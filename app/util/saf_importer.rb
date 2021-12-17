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
# The `content` file is a plain text file containing a newline-separated list
# of files associated with an item. A filename may optionally be followed by
# any combination of the following (where \t is a tab character):
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
  # @param pathname [String] Pathname of the root package directory.
  # @param primary_collection [Collection] Collection to import the items into.
  # @param mapfile_path [String] Pathname of the mapfile.
  # @param print_progress [Boolean] Whether to print progress updates to
  #                                 stdout.
  # @return [void]
  # @raises [StandardError] Various error types depending on all of the things
  #                         that can go wrong. If this occurs, refer to the
  #                         mapfile for an inventory of items that were
  #                         imported successfully prior to the error occurring.
  #
  def import_from_path(pathname:,
                       primary_collection:,
                       mapfile_path:,
                       print_progress: false)
    item_dirs = Dir.entries(pathname).reject{ |d| %w(. ..).include?(d) }.sort

    # Read the list of items in the mapfile, if one exists. These will be
    # skipped during the import.
    if File.exists?(mapfile_path)
      imported_item_dirs = mapfile_items(File.read(mapfile_path))
      item_dirs         -= imported_item_dirs
    end

    progress = print_progress ? Progress.new(item_dirs.length) : nil

    File.open(mapfile_path, "wb") do |mapfile|
      # Iterate through each item directory.
      item_dirs.each_with_index do |item_dir, index|
        progress&.report(index, "Importing #{item_dirs.length} items from SAF package")
        # Work inside a transaction to avoid any incompletely created items.
        ActiveRecord::Base.transaction do
          item = ImportItemCommand.new(primary_collection: primary_collection).execute
          item.assign_handle

          # Add bitstreams corresponding to each line in the content file.
          item_dir_path     = File.join(pathname, item_dir)
          content_file_path = File.join(item_dir_path, "content")
          unless File.exists?(content_file_path)
            raise IOError, "Missing content file for item #{item_dir}"
          end
          add_bitstreams_from_file(item:              item,
                                   content_file_path: content_file_path)

          # Add metadata corresponding to the Dublin Core metadata file.
          dc_path = File.join(item_dir_path, "dublin_core.xml")
          unless File.exists?(dc_path)
            raise IOError, "Missing dublin_core.xml file for item #{item_dir}"
          end
          add_metadata(item:                   item,
                       metadata_relative_path: dc_path,
                       metadata_file_content:  File.read(dc_path))

          # Add metadata corresponding to any other metadata files.
          Dir.glob(File.join(item_dir_path, "metadata*.xml")) do |metadata_file_path|
            add_metadata(item:                   item,
                         metadata_relative_path: metadata_file_path,
                         metadata_file_content:  File.read(metadata_file_path))
          end

          item.approve
          item.save!
          mapfile.write("#{item_dir}\t#{item.handle.handle}\n")
          item.ingest_into_medusa
        end
      end
    end
  end

  ##
  # @param import [Import]
  # @return [void]
  # @raises [StandardError] Various error types depending on all of the things
  #                         that can go wrong. If this occurs, the
  #                         {Import#imported_items} attribute will be updated
  #                         with an inventory of items that were imported
  #                         successfully prior to the error occurring.
  #
  def import_from_s3(import)
    client            = S3Client.instance
    bucket            = ::Configuration.instance.aws[:bucket]
    item_key_prefixes = import.item_key_prefixes
    imported_items    = import.imported_items || []
    item_key_prefixes.reject!{ |k| imported_items.select{ |i| k.end_with?(i['item_id']) }.any? }

    import.update!(files:  import.object_keys,
                   status: Import::Status::RUNNING)

    # Iterate through each item pseudo-directory.
    item_key_prefixes.each_with_index do |item_dir, index|
      # Work inside a transaction to avoid any incompletely created items.
      Import.transaction do
        item = ImportItemCommand.new(primary_collection: import.collection).execute
        item.assign_handle

        # Add bitstreams corresponding to each line in the content file.
        content_file_key = item_dir + "/content"
        unless client.object_exists?(bucket: bucket, key: content_file_key)
          raise IOError, "Missing content file for item #{item_dir}"
        end
        content = client.get_object(bucket: bucket,
                                    key:    content_file_key).body.read
        add_bitstreams_from_s3(item:                 item,
                               item_key_prefix:      item_dir,
                               content_file_key:     content_file_key,
                               content_file_content: content)

        # Add metadata corresponding to the Dublin Core metadata file.
        dc_key = item_dir + "/dublin_core.xml"
        unless client.object_exists?(bucket: bucket, key: dc_key)
          raise IOError, "Missing dublin_core.xml file for item #{item_dir}"
        end
        content = client.get_object(bucket: bucket, key: dc_key).body.read
        add_metadata(item:                   item,
                     metadata_relative_path: dc_key,
                     metadata_file_content:  content)

        # Add metadata corresponding to any other metadata files.
        item_object_keys = client.objects(bucket:     bucket,
                                          key_prefix: item_dir)
        item_object_keys.map(&:key).select{ |k| k.match(/\/metadata_.+.xml$/) }.each do |metadata_key|
          content = client.get_object(bucket: bucket,
                                      key:    metadata_key).body.read
          add_metadata(item:                   item,
                       metadata_relative_path: metadata_key,
                       metadata_file_content:  content)
        end

        item.approve
        item.save!
        imported_items << {
          item_id: item_dir.split("/").last,
          handle:  item.handle.handle
        }
        import.update!(percent_complete: index / item_key_prefixes.length.to_f,
                       imported_items:   imported_items)
        item.ingest_into_medusa
      end
    end
  rescue => e
    import.update!(status:             Import::Status::FAILED,
                   last_error_message: e.message)
    raise e
  else
    import.update!(status: Import::Status::SUCCEEDED)
  end


  private

  ##
  # @param item [Item]
  # @param content_file_path [String] Full path of the `content` file.
  #
  def add_bitstreams_from_file(item:, content_file_path:)
    File.open(content_file_path, "r").each_with_index do |line, line_index|
      line.strip!
      next if line.blank?
      file_path = filename = description = nil
      primary   = false
      bundle    = Bitstream::Bundle::CONTENT
      line.split("\t").each do |part|
        if part.start_with?("bundle:")
          bundle = Bitstream::Bundle.for_string(part.split(":").last)
        elsif part.start_with?("description:")
          description = part[12..]
        elsif part.start_with?("primary:")
          primary = part[8..] == "true"
        elsif part.start_with?("permission:")
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
      unless File.exists?(file_path)
        raise IOError, "File on line #{line_index + 1} of "\
                       "#{content_file_path} does not exist: #{file_path}"
      end

      bs = Bitstream.create(item:              item,
                            permanent_key:     Bitstream.permanent_key(item.id, filename),
                            original_filename: filename,
                            bundle:            bundle,
                            primary:           primary,
                            description:       description,
                            length:            File.size(file_path))
      File.open(file_path, "r") do |file|
        bs.upload_to_permanent(file)
      end
    end
  end

  ##
  # @param item [Item]
  # @param item_key_prefix [String]
  # @param content_file_key [String]
  # @param content_file_content [String] Contents of the content file.
  #
  def add_bitstreams_from_s3(item:,
                             item_key_prefix:,
                             content_file_key:,
                             content_file_content:)
    client = S3Client.instance
    bucket = Configuration.instance.aws[:bucket]
    content_file_content.split("\n").each_with_index do |line, line_index|
      line.strip!
      next if line.blank?
      file_key = filename = description = nil
      primary  = false
      bundle   = Bitstream::Bundle::CONTENT
      line.split("\t").each do |part|
        if part.start_with?("bundle:")
          bundle = Bitstream::Bundle.for_string(part.split(":").last)
        elsif part.start_with?("description:")
          description = part[12..]
        elsif part.start_with?("primary:")
          primary = part[8..] == "true"
        elsif part.start_with?("permission:")
          # we are ignoring this
        elsif part.match?(/.*[:].*/)
          raise IOError, "Unrecognized flag (#{part}) in "\
                         "#{content_file_key}"
        else
          filename = part
          file_key = [item_key_prefix, filename].join("/")
        end
      end
      unless file_key
        raise IOError, "No file on line #{line_index + 1} of "\
                       "#{content_file_key}"
      end
      unless client.object_exists?(bucket: bucket, key: file_key)
        raise IOError, "File on line #{line_index + 1} of "\
                       "#{content_file_key} does not exist: "\
                       "#{file_key}"
      end

      length = client.head_object(bucket: bucket, key: file_key).content_length
      bs = Bitstream.create(item:              item,
                            permanent_key:     Bitstream.permanent_key(item.id, filename),
                            original_filename: filename,
                            bundle:            bundle,
                            primary:           primary,
                            description:       description,
                            length:            length)
      client.copy_object(copy_source: "/#{bucket}/#{file_key}",
                         bucket:      bucket,
                         key:         bs.permanent_key)
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
    doc    = Nokogiri::XML(metadata_file_content)
    schema = doc.xpath("/*/@schema").text
    schema = "dc" if schema.blank?
    doc.xpath("//dcvalue").each do |node|
      element   = node["element"]
      qualifier = node["qualifier"]
      name      = "#{schema}:#{element}"
      name     += ":#{qualifier}" if qualifier && qualifier != "none"

      re = RegisteredElement.find_by_name(name)
      unless re
        raise IOError, "Metadata file (#{metadata_relative_path}) contains an "\
                       "element (#{name}) that does not exist in the registry"
      end
      item.elements.build(registered_element: re,
                          string:             node.text)
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
