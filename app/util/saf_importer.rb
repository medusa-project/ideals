# frozen_string_literal: true

##
# SAF is a DSpace package format containing a batch of things to import.
#
# # Package structure
#
# At the root of a SAF package is a directory known as the "archive directory."
# Each subdirectory within represents a particular item.
#
# Each item directory contains a file named `content`, which is a manifest of
# files that compose the item. These files are all present in the item
# directory. The format of the content file is described below.
#
# The item directory also contains an XML file that encodes the item's
# metadata.
#
# ## `content` file format
#
# The `content` (or `contents`) file is a plain text file containing a
# newline-separated list of files associated with an item. A filename may
# optionally be followed by any combination of the following (where \t is a tab
# character):
#
# * `\tbundle:BUNDLENAME`
#     * The name of the bundle to which the bitstream should be added. Without
#       specifying the bundle, items will go into the default bundle,
#       {Bitstream::Bundle::CONTENT}.
# * `\tdescription:DESCRIPTION`
#     * Text of the file's description.
# * `\tprimary:true`
#     * Specifies the primary bitstream.
#
# All keys above (`bundle:` etc.) may be lowercase or uppercase.
#
# Some packages (e.g. those exported by Vireo) also list the item's metadata
# files (`dublin_core.xml`, `metadata_*.xml`) and `action_log.csv` in the
# content file. These lines are skipped and are not ingested as bitstreams.
# (Metadata files are still read as metadata as described below.)
#
# ## Metadata file format
#
# DSpace was created with qualified Dublin Core in mind, so at a minimum there
# exists one file named `dublin_core.xml`, which contains a form like:
#
# ```
# <dublin_core>
#     <dcvalue element="title" qualifier="none">A Tale of Two Cities</dcvalue>
#     <dcvalue element="date" qualifier="issued">1990</dcvalue>
# </dublin_core>
# ```
# There is no schema validation, but it keeps this basic structure. This would
# create values for the elements `dc:title` (if qualifier is "none" then the
# qualifier is simply omitted) and `dc:date:issued`. In this default file the
# schema prefix will always be `dc`.
#
# For each additional schema, a file named like `metadata_{prefix}.xml` exists.
# Even though the schema may not be related to Dublin Core, the XML is
# formatted identically to `dublin_core.xml` with the exception that the root
# element receives an attribute that identifies the schema prefix.
#
# For TDL’s ETD schema used with Vireo there is a `metadata_etd.xml` file with
# contents like:
#
# ```
# <dublin_core schema="etd">
#     <dcvalue element="degree" qualifier="department">Computer Science</dcvalue>
#     <dcvalue element="degree" qualifier="level">Masters</dcvalue>
#     <dcvalue element="degree" qualifier="grantor">Michigan Institute of Technology</dcvalue>
# </dublin_core>
# ```
#
# Note that this application doesn't include DSpace's notion of schemas, so we
# can alter the batch import to support metadata forms as needed.
#
# `metadata_local.xml` (exported by Vireo) is ignored entirely.
#
# # Error recovery
#
# Any error encountered during the import will terminate the import.
#
# As each item is imported, it is written to a "mapfile" which is a plain text
# file in the following format:
#
# `{directory_name}\t{item_handle}`
#
# (With `\t` representing the tab character and the directory name being the
# name of the directory in the SAF package representing the new item.) When the
# import is re-run with the same mapfile, any items already present in it are
# skipped, and newly imported items are appended to it. The mapfile is created
# if it does not exist. Skipped items are listed in the log and, when
# `print_progress` is true, on stdout.
#
# When a mapfile is supplied, one database transaction is used per item, to
# prevent any incompletely created items.
#
# An import can also be run without supplying a mapfile. In this case, the
# whole import runs inside a single transaction, which is rolled back when an
# error occurs.
#
# @see https://wiki.lyrasis.org/display/DSDOC6x/Importing+and+Exporting+Items+via+Simple+Archive+Format
#
class SafImporter

  ##
  # Metadata files that are never read as metadata, even though they match
  # the `metadata_*.xml` pattern.
  #
  IGNORED_METADATA_FILES = %w[metadata_local.xml].freeze

  ##
  # Non-metadata files that some packages (e.g. Vireo exports) list in the
  # content file, but which must not be ingested as bitstreams.
  #
  NON_CONTENT_FILES = %w[action_log.csv].freeze

  ##
  # @param pathname [String]               Pathname of the package directory
  #                                        root.
  # @param primary_collection [Collection] Collection to import the items into.
  # @param mapfile_path [String]           Pathname of the mapfile. Only used
  #                                        for imports from the local file
  #                                        system.
  # @param print_progress [Boolean]        Whether to print progress updates to
  #                                        stdout.
  # @param task [Task]                     Supply to receive status updates.
  # @return [void]
  # @raises [StandardError] Various error types depending on all of the things
  #                         that can go wrong. If this occurs, refer to the
  #                         mapfile for an inventory of items that were
  #                         imported successfully prior to the error occurring.
  #
  def import_from_path(pathname:,
                       primary_collection:,
                       mapfile_path:       nil,
                       print_progress:     false,
                       task:               nil)
    item_dirs = Dir.glob(pathname + "/*").select{ |n| File.directory?(n) }.sort

    # Read the list of items in the mapfile, if one exists, in order to skip
    # them during the import.
    mapfile_contents = ""
    if mapfile_path && File.exist?(mapfile_path)
      mapfile_contents   = File.read(mapfile_path)
      imported_item_dirs = mapfile_items(mapfile_contents)
      skipped_dirs, item_dirs = item_dirs.partition do |d|
        imported_item_dirs.include?(d.delete_prefix(pathname + "/"))
      end
      report_skipped_items(skipped_dirs.map{ |d| d.delete_prefix(pathname + "/") },
                           print: print_progress)
    end
    progress = print_progress ? Progress.new(item_dirs.length) : nil

    # If we have a mapfile, use one transaction per item. If we don't have
    # a mapfile, use one transaction for all items.
    if mapfile_path
      # Append, so that entries from previous runs are preserved.
      File.open(mapfile_path, "ab") do |mapfile|
        # Terminate a partial last line left over from a crash, so that new
        # entries start on their own line.
        if mapfile_contents.present? && !mapfile_contents.end_with?("\n")
          mapfile.write("\n")
        end
        item_dirs.each_with_index do |item_dir, index|
          import_item(item_dir:           item_dir,
                      num_item_dirs:      item_dirs.length,
                      primary_collection: primary_collection,
                      pathname:           pathname,
                      mapfile:            mapfile,
                      index:              index,
                      progress:           progress,
                      task:               task)
        end
      end
    else
      ActiveRecord::Base.transaction do
        item_dirs.each_with_index do |item_dir, index|
          import_item(item_dir:           item_dir,
                      num_item_dirs:      item_dirs.length,
                      primary_collection: primary_collection,
                      pathname:           pathname,
                      index:              index,
                      progress:           progress,
                      task:               task)
        end
      end
    end
    task&.succeed
  end


  private

  def import_item(item_dir:,
                  num_item_dirs:,
                  primary_collection:,
                  pathname:,
                  mapfile: nil,
                  index:,
                  progress:,
                  task:)
    status_text = "Importing #{num_item_dirs} items from SAF package"
    progress&.report(index, status_text)
    task&.progress(index / num_item_dirs.to_f, status_text: status_text)

    # Work inside a transaction to avoid an incompletely created item.
    item = ActiveRecord::Base.transaction do
      item = ImportItemCommand.new(primary_collection: primary_collection).execute
      begin
        item.assign_handle

        # Add bitstreams corresponding to each line in the content file.
        content_file_path = File.join(item_dir, "content")
        unless File.exist?(content_file_path)
          content_file_path = File.join(item_dir, "contents")
          unless File.exist?(content_file_path)
            raise IOError, "Missing content file for item #{item_dir}"
          end
        end
        add_bitstreams(item:              item,
                       content_file_path: content_file_path)

        # Add metadata corresponding to the Dublin Core metadata file.
        dc_path = File.join(item_dir, "dublin_core.xml")
        unless File.exist?(dc_path)
          raise IOError, "Missing dublin_core.xml file for item #{item_dir}"
        end
        add_metadata(item:                   item,
                     metadata_relative_path: dc_path,
                     metadata_file_content:  File.read(dc_path))

        # Add metadata corresponding to any other metadata files.
        Dir.glob(File.join(item_dir, "metadata*.xml")) do |metadata_file_path|
          next if IGNORED_METADATA_FILES.include?(File.basename(metadata_file_path))
          add_metadata(item:                   item,
                       metadata_relative_path: metadata_file_path,
                       metadata_file_content:  File.read(metadata_file_path))
        end

        item.approve
        item.save!
      rescue => e
        item.handle&.delete_from_server
        task&.fail(detail:    e.message,
                   backtrace: e.backtrace)
        raise e
      end
      item
    end

    # Record the item only after its transaction has committed, and flush
    # immediately so that the entry survives a crash.
    if mapfile
      item_rel_path = item_dir.delete_prefix(pathname + "/")
      mapfile.write("#{item_rel_path}\t#{item.handle.handle}\n")
      mapfile.flush
    end
  end

  ##
  # @param item [Item]
  # @param content_file_path [String] Full path of the `content` file.
  #
  def add_bitstreams(item:, content_file_path:)
    File.open(content_file_path, "r").each_with_index do |line, line_index|
      line.strip!
      next if line.blank?
      file_path = filename = description = nil
      primary   = false
      bundle    = Bitstream::Bundle::CONTENT
      line.split("\t").each do |part|
        lc_part = part.downcase
        if lc_part.start_with?("bundle:")
          bundle = Bitstream::Bundle.for_string(part.split(":").last.upcase)
        elsif lc_part.start_with?("description:")
          description = part[12..]
        elsif lc_part.start_with?("primary:")
          primary = part[8..] == "true"
        elsif lc_part.start_with?("permission:")
          # we are ignoring this
        elsif part.match?(/.*[:].*/)
          raise IOError, "Unrecognized flag (#{part}) in content file: "\
                         "#{content_file_path}"
        else
          filename      = part
          item_dir_path = File.dirname(content_file_path)
          file_path     = File.join(item_dir_path, filename)
        end
      end
      unless file_path
        raise IOError, "No file on line #{line_index + 1} of #{content_file_path}"
      end
      next if non_content_file?(filename)
      unless File.exist?(file_path)
        raise IOError, "File on line #{line_index + 1} of "\
                       "#{content_file_path} does not exist: #{file_path}"
      end

      permanent_key = Bitstream.permanent_key(institution_key: item.institution.key,
                                              item_id:         item.id,
                                              filename:        filename)
      bs = Bitstream.create(item:          item,
                            permanent_key: permanent_key,
                            filename:      filename,
                            bundle:        bundle,
                            primary:       primary,
                            description:   description,
                            length:        File.size(file_path))
      bs.upload_to_permanent(file_path)
    end
  end

  ##
  # Values that are empty or whitespace-only are ignored. This check happens
  # before the registry lookup, so a blank value for an element that is not in
  # the registry does not raise an error. Ignored values don't consume a
  # position.
  #
  # @param item [Item]
  # @param metadata_relative_path [String]
  # @param metadata_file_content [String] Contents of a metadata file.
  #
  def add_metadata(item:,
                   metadata_relative_path:,
                   metadata_file_content:)
    doc      = Nokogiri::XML(metadata_file_content)
    schema   = doc.xpath("/*/@schema").text
    schema   = "dc" if schema.blank?
    tmp_name = nil
    position = 1
    doc.xpath("//dcvalue").each do |node|
      value = node.text.strip
      next if value.blank?
      element   = node["element"]
      qualifier = node["qualifier"]
      name      = "#{schema}:#{element}"
      name     += ":#{qualifier}" if qualifier && qualifier != "none"
      position  = 1 if name != tmp_name
      tmp_name  = name

      re = RegisteredElement.where(name:        name,
                                   institution: item.institution).limit(1).first
      unless re
        raise IOError, "Metadata file (#{metadata_relative_path}) contains an "\
                       "element (#{name}) that does not exist in the registry"
      end
      item.elements.build(registered_element: re,
                          string:             value,
                          position:           position)
      position += 1
    end
  end

  ##
  # Logs, and optionally prints, the item directories that are being skipped
  # because they are already present in the mapfile. Does nothing if there are
  # none.
  #
  # @param skipped_dirs [Enumerable<String>] Item directory names.
  # @param print [Boolean] Whether to also print to stdout.
  #
  def report_skipped_items(skipped_dirs, print:)
    return if skipped_dirs.empty?
    message = "Skipping #{skipped_dirs.length} item(s) already present in " \
              "the mapfile:\n" + skipped_dirs.map{ |d| "  #{d}" }.join("\n")
    Rails.logger.info(message)
    puts message if print
  end

  ##
  # @param mapfile_contents [String]
  # @return [Set<String>] Item directory names that have been imported. Lines
  #                       lacking a handle (e.g. a partial line written during
  #                       a crash) are ignored.
  #
  def mapfile_items(mapfile_contents)
    mapfile_contents.to_s.each_line.filter_map do |line|
      dir, handle = line.chomp.split("\t")
      dir if dir.present? && handle.present?
    end.to_set
  end

  ##
  # @param filename [String] Filename from a line of the content file.
  # @return [Boolean] Whether the file is a metadata or log file that must not
  #                   be ingested as a bitstream.
  #
  def non_content_file?(filename)
    filename == "dublin_core.xml" ||
      filename.match?(/\Ametadata.*\.xml\z/) ||
      NON_CONTENT_FILES.include?(filename)
  end

end
