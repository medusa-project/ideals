namespace :elements do

  desc "Reports the number of uses by items"
  task :report_item_frequencies, [:institution_key, :element_name, :start_ymd, :end_ymd] => :environment do |task, args|
    institution = Institution.find_by_key(args[:institution_key])
    reg_e       = RegisteredElement.find_by(institution: institution,
                                            name:        args[:element_name])
    results     = AscribedElement.usage_frequencies(element:    reg_e,
                                                    start_time: Time.parse(args[:start_ymd]),
                                                    end_time:   Time.parse(args[:end_ymd]))

    output_string = CSV.generate do |csv|
      results.each do |row|
        csv << [row['string'], row['item_count']]
      end
    end
    puts output_string
  end

  desc "Changes the name of a registered element"
  task :rename_element, [:registered_element_id, :new_element_name] => :environment do |task, args|
    rename_registered_element(args[:registered_element_id], args[:new_element_name])
  end

  desc "Migrates all ascribed elements from one registered element to another"
  task :migrate_ascribed, [:institution_key,
                           :from_registered_element_name,
                           :to_registered_element_name] => :environment do |task, args|
    # Institution
    institution = Institution.find_by_key(args[:institution_key])
    unless institution
      puts "No such institution." and return
    end
    # "From" RegisteredElement
    from_re = RegisteredElement.find_by(institution: institution,
                                        name:        args[:from_registered_element_name])
    unless from_re
      puts "No such \"from\" element." and return
    end
    # "To" RegisteredElement
    to_re = RegisteredElement.find_by(institution: institution,
                                      name:        args[:to_registered_element_name])
    unless to_re
      puts "No such \"to\" -element." and return
    end
    from_re.migrate_ascribed_elements(to_registered_element: to_re,
                                      reindex_items:         false)
    puts "Done. Note that any affected items will have to be reindexed manually."
  end

end

def rename_registered_element(registered_element_id, new_element_name)
  reg_element=RegisteredElement.where(id: registered_element_id)
  puts "\n########## Processing record: "
  puts reg_element.inspect
  reg_element.update(name: new_element_name)
  puts "\n########## Renamed: "
  puts reg_element.inspect
end

