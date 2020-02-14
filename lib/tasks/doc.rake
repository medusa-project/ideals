namespace :doc do

  desc 'Generate documentation'
  task :generate => :environment do |task, args|
    doc_path = File.join(Rails.root, 'doc')
    FileUtils.rm_rf(doc_path)
    `yard --markup markdown`
    puts "Documentation generated at #{doc_path}"
    `open doc/index.html` if RUBY_PLATFORM.include?('darwin')
  end

end
