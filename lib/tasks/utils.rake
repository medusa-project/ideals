require 'rake'


namespace :utils do
  namespace :SAF_edit do
    desc "Remove Superfluous Metadata Element from SAF Metadata Files"
    task :remove_element, [:package_path, :metadata_element, :metadatafile_name] => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          metadata_path=File.join(path, args[:metadatafile_name])
          SafUtils.new.remove_metadata_element(metadata_path, args[:metadata_element])
        end
      end
    end
    task :rename_package_file, [:package_path, :filename, :new_name] => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          SafUtils.new.rename_file(path, args[:filename], args[:new_name])
        end
      end

    end
    task :remove_metadata_whitespace, [:package_path, :metadatafile_name]  => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          metadata_path=File.join(path, args[:metadatafile_name])
          SafUtils.new.remove_metadata_whitespace(metadata_path)
        end
      end
    end
    task :change_orignal_to_content_bundle, [:package_path]  => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          content_path=File.join(path, "content")
          SafUtils.new.orignal_to_content_bundle(content_path)
        end
      end
    end
    task :check_content_files, [:package_path]  => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          content_path=File.join(path, "content")
          SafUtils.new.check_content_files(content_path)
        end
      end
    end
    task :print_title_author, [:package_path]  => :environment do |task, args|
      Dir.foreach(args[:package_path]) do|level1dir_name|
        path=File.join(args[:package_path],level1dir_name)
        if level1dir_name == "." or level1dir_name == ".."
          next
        elsif File.directory?(path)
          puts "processing #{path}"
          content_path=File.join(path, "dublin_core.xml")
          SafUtils.new.print_title_author(content_path)
        end
      end
    end

  end

end


