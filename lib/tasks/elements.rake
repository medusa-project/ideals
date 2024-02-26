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
  task :migrate_ascribed_element, [:registered_element_id, :new_element_id] => :environment do |task, args|
    from_re = RegisteredElement.find(args[:registered_element_id])
    to_re   = RegisteredElement.find(args[:new_element_id])
    from_re.migrate_ascribed_elements(to_registered_element: to_re)
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

