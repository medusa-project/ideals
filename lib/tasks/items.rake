require 'rake'

namespace :items do

  desc "Delete expired embargoes"
  task delete_expired_embargoes: :environment do
    Embargo.where("expires_at < NOW()").delete_all
  end

  desc "Import items from a SAF package"
  task :import_saf, [:package_path, :mapfile_path, :collection_id] => :environment do |task, args|
    # Argument validation and setup.
    collection   = Collection.find(args[:collection_id])
    package_path = File.expand_path(args[:package_path])
    mapfile_path = File.expand_path(args[:mapfile_path])
    # Do the import.
    SafImporter.new.import_from_path(pathname:           package_path,
                                     primary_collection: collection,
                                     mapfile_path:       mapfile_path,
                                     print_progress:     true)
    puts "Import succeeded."
  end

  desc "Transform dates to ISO 8601"
  task transform_dates: :environment do # TODO: this can be removed after it has been done in production
    months      = %w(January February March April May June July August September
                     October November December)
    reg_e_ids   = RegisteredElement.where(input_type: RegisteredElement::InputType::DATE).pluck(:id)
    asc_es      = AscribedElement.where(registered_element_id: reg_e_ids)
    asc_e_count = asc_es.count
    progress    = Progress.new(asc_e_count)
    num_changed = 0
    AscribedElement.transaction do
      asc_es.find_each.with_index do |asc_e, index|
        months.each do |month|
          if asc_e.string.start_with?(month)
            asc_e.update!(string: Date.parse(asc_e.string))
            num_changed += 1
            break
          end
        end
        progress.report(index, "Transforming #{asc_e_count} dates")
      end
    end
    puts "#{num_changed} elements changed"
  end

end