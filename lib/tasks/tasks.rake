namespace :tasks do

  desc "Delete pending tasks"
  task :delete_pending => :environment do
    Task.where(status: Task::Status::PENDING).destroy_all
  end

end