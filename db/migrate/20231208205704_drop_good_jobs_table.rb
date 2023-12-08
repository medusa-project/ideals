class DropGoodJobsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :good_jobs
    drop_table :good_job_settings
  end
end
