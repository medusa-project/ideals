#

namespace :metadata do
  desc "Changes the name of a registered element"
  task :rename_element, [:registered_element_id, :new_element_name] => :environment do |task, args|
    rename_registered_element(args[:registered_element_id], args[:new_element_name])
  end
  desc "migrates all ascribed element values from one particular registered element to another"
  task :migrate_ascribed_element, [:ascribed_element_id, :new_element_id] => :environment do |task, args|
    migrate_ascribed_element(args[:ascribed_element_id], args[:new_element_id])
  end
end

def migrate_ascribed_element(previous_registered_element_id, new_registered_element_id)
  asc_elements=AscribedElement.where(registered_element_id: previous_registered_element_id)
  registered=RegisteredElement.where(id: new_registered_element_id)
  puts registered.inspect
  asc_elements.each do |asc_element|
    puts "\n###########  Processing: #{asc_element.inspect}"
    asc_element.update(registered_element_id: new_registered_element_id)
    puts "\n###########  Migrated: #{asc_element.inspect}"
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

