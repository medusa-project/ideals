# frozen_string_literal: true

##
# Facade class that takes in an import file or package and invokes one of the
# format-specific importer implementations to import it, downloading and/or
# decompressing it first if necessary.
#
# The import file may be located on the file system (located by {Import#file})
# or in the application S3 bucket (located by {Import#file_key}).
#
# # Supported Formats
#
# 1. Zip file containing:
#     * SAF package
#     * CSV package
# 2. CSV file
#
# For zip files, there may or may not be an enclosing directory/folder at the
# root of the file contents.
#
class Importer

  ##
  # @param import [Import] Instance with an import file attached.
  # @param submitter [User]
  # @return [Integer] One of the {Import::Format} constant values, used for
  #                   testing.
  #
  def import(import, submitter)
    import.task ||= Task.new
    import.task.update!(name:        self.class.name,
                        institution: submitter&.institution,
                        user:        submitter,
                        started_at:  Time.now,
                        status:      Task::Status::RUNNING,
                        status_text: "Importing items")
    # Download the file onto the local filesystem, if it does not already
    # reside there.
    file = import.file
    unless File.exist?(file)
      import.task.update!(status_text: "Downloading the import file")
      import.download
    end
    # If the import is a compressed file, download and decompress it. SAF and
    # CSV packages are supported within compressed files.
    if file.split(".").last.downcase == "zip"
      import.task.update!(status_text: "Decompressing the package")
      tmpdir = Dir.mktmpdir
      `unzip "#{file}" -d #{tmpdir}`
      # Try to detect the package format.
      root_files_path = tmpdir + "/*"
      # We want to support package files with or without a top-level enclosing
      # folder. If we see only one top-level node, and it's a folder, we assume
      # it's an enclosing folder, unless it contains a content file, in which
      # case it has to be a one-item SAF package.
      root_files = Dir.glob(root_files_path).reject{ |n| n.end_with?("__MACOSX") }
      if root_files.length == 1 && File.directory?(root_files.first) &&
          !File.exist?(File.join(root_files.first, "content")) &&
          !File.exist?(File.join(root_files.first, "contents"))
        root_files_path += "/*"
      end
      root_files     = Dir.glob(root_files_path).select{ |n| File.file?(n) }
      # Are there any SAF content files?
      content_files  = Dir.glob(root_files_path + "/content").select{ |n| File.file?(n) }
      content_files += Dir.glob(root_files_path + "/contents").select{ |n| File.file?(n) }
      if content_files.any?
        import.task.update!(status_text: "Importing items from SAF package")
        SafImporter.new.import_from_path(pathname:           Dir[tmpdir + "/*"].first,
                                         primary_collection: import.collection,
                                         mapfile_path:       File.join(tmpdir, "mapfile.tmp"),
                                         task:               import.task)
        return Import::Format::SAF
      elsif root_files.find{ |f| f.downcase.end_with?(".csv") }
        import.task.update!(status_text: "Importing items from CSV package")
        CsvImporter.new.import(csv:                File.read(root_files.find{ |f| f.downcase.end_with?(".csv") }),
                               file_paths:         Dir[tmpdir + "/**/*"],
                               submitter:          submitter,
                               primary_collection: import.collection,
                               imported_items:     [],
                               task:               import.task)
        return Import::Format::CSV_PACKAGE
      else
        import.task.fail(detail: "Unable to detect the package format.")
      end
    elsif file.split(".").last.downcase == "csv"
      import.task.update!(status_text: "Importing items from CSV file")
      CsvImporter.new.import(csv:                File.read(file),
                             submitter:          submitter,
                             primary_collection: import.collection,
                             imported_items:     [],
                             task:               import.task)
      return Import::Format::CSV_FILE
    else
      import.task.fail(detail: "The file to import must have a .zip or .csv extension.")
    end
  end

end