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
#      <dcvalue element="degree" qualifier="department">Computer Science</dcvalue>
#      <dcvalue element="degree" qualifier="level">Masters</dcvalue>
#      <dcvalue element="degree" qualifier="grantor">Michigan Institute of Technology</dcvalue>
# </dublin_core>
# ```
#
# Note that this application doesn't include DSpace's notion of schemas, so we
# can alter the batch import to support metadata forms as needed.
#
# # Error recovery
#
# Any error encountered during the import will terminate the import. As each
# item is imported, it is written to a "mapfile" which is a plain text file in
# the following format:
#
# `{directory_name}\t{item_handle}`
#
# (With `\t` representing the tab character and the directory name being the
# name of the directory in the SAF package representing the new item.) When the
# import is re-run, any items already present in the mapfile are skipped.
#
# @see https://wiki.lyrasis.org/display/DSDOC6x/Importing+and+Exporting+Items+via+Simple+Archive+Format
#
class SafImporter

  ##
  # @param pathname [String]               Pathname of the package directory
  #                                        root.
  # @param primary_collection [Collection] Collection to import the items into.
  # @param mapfile_path [String]           Pathname of the mapfile.
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
                       mapfile_path:,
                       print_progress: false,
                       task:           nil)
    item_dirs = Dir.glob(pathname + "/*").select{ |n| File.directory?(n) }.sort

    # Read the list of items in the mapfile, if one exists, in order to skip
    # them during the import.
    if File.exist?(mapfile_path)
      imported_item_dirs = mapfile_items(File.read(mapfile_path))
      imported_item_dirs.each do |imported_dir|
        item_dirs = item_dirs.reject{ |d| d.end_with?("/" + imported_dir) }
      end
    end
    progress = print_progress ? Progress.new(item_dirs.length) : nil

    File.open(mapfile_path, "wb") do |mapfile|
      # Iterate through each item directory.
      item_dirs.each_with_index do |item_dir, index|
        status_text = "Importing #{item_dirs.length} items from SAF package"
        progress&.report(index, status_text)
        task&.progress(index / item_dirs.length.to_f,
                       status_text: status_text)

        # Work inside a transaction to avoid any incompletely created items.
        ActiveRecord::Base.transaction do
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
          else
            item_rel_path = item_dir.gsub(pathname + "/", "")
            mapfile.write("#{item_rel_path}\t#{item.handle.handle}\n")
          end
        end
      end
    end
    task&.succeed
  end


  private

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
                          string:             node.text.strip,
                          position:           position)
      position += 1
    end
  end

  def mapfile_items(mapfile_contents)
    return [] if mapfile_contents.blank?
    mapfile_contents.
      split("\n").
      map{ |line| line.split("\t").first }.
      select(&:present?)
  end

end
