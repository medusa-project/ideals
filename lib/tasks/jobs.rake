namespace :jobs do

  desc 'Clear all jobs'
  task :clear => :environment do
    ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs;")
  end

  desc "List jobs"
  task list: :environment do
    sql = "SELECT * FROM delayed_jobs ORDER BY created_at DESC;"
    puts ActiveRecord::Base.connection.exec_query(sql)
  end

  desc 'Run a test job'
  task :test => :environment do
    if Rails.application.config.active_job.queue_adapter == :async
      puts "The :async ActiveJob adapter doesn't work with rake tasks. Exiting."
    else
      task = Task.create!(name: SleepJob.to_s)
      SleepJob.perform_later(duration: 30, task: task)
      "Job enqueued. You should see a new task appear at /tasks."
    end
  end

end