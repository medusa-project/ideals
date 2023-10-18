namespace :jobs do

  desc 'Clear all jobs'
  task :clear => :environment do
    ActiveRecord::Base.connection.execute("DELETE FROM good_jobs;")
  end

  desc "List jobs"
  task list: :environment do
    sql = "SELECT * FROM good_jobs ORDER BY created_at DESC;"
    puts ActiveRecord::Base.connection.exec_query(sql)
  end

  desc 'Run a test job'
  task :test => :environment do
    SleepJob.perform_later(duration: 30)
    puts "Job enqueued. You should see a new task in the tasks list at /tasks."
  end

end