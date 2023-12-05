json.id @task.id
json.name @task.name
json.percent_complete @task.percent_complete
json.status Task::Status.to_s(@task.status)
json.status_text @task.status_text
json.detail @task.detail
json.backtrace @task.backtrace
json.indeterminate @task.indeterminate
json.job_id @task.job_id
json.institution do
  json.id @task.institution_id
  json.uri institution_url(@task.institution)
end
if @task.user
  json.user do
    json.id @task.user.id
    json.uri user_url(@task.user)
  end
end
json.created_at @task.created_at
json.started_at @task.started_at
json.stopped_at @task.stopped_at
json.updated_at @task.updated_at
