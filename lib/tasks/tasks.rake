namespace :tasks do

  desc "Delete pending tasks"
  task :delete_pending => :environment do
    Task.where(status: Task::Status::PENDING).delete_all
  end

  desc "Fail pending tasks"
  task :fail_pending => :environment do
    Task.where(status: Task::Status::PENDING).
      update_all(status: Task::Status::FAILED)
  end

  desc "Delete running tasks"
  task :delete_running => :environment do
    Task.where(status: Task::Status::RUNNING).delete_all
  end

  desc "Fail running tasks"
  task :fail_running => :environment do
    Task.where(status: Task::Status::RUNNING).
      update_all(status: Task::Status::FAILED)
  end

end