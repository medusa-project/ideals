namespace :elements do

  desc "Reports the number of uses by items"
  task :report_item_frequencies, [:institution_key, :element_name] => :environment do |task, args|
    institution = Institution.find_by_key(args[:institution_key])
    reg_e       = RegisteredElement.find_by(institution: institution,
                                            name:        args[:element_name])
    results     = AscribedElement.usage_frequencies(reg_e)

    output_string = CSV.generate do |csv|
      results.each do |row|
        csv << [row['string'], row['item_count']]
      end
    end
    puts output_string
  end

end
