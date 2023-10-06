# frozen_string_literal: true

json.set! "class", @import.class.to_s
json.uri import_url(@import)

json.extract! @import, :id, :filename, :format, :length,
              :created_at, :updated_at

if @import.filename.present? && @import.length.present? && policy(@import).create?
  json.upload_url @import.presigned_upload_url
end

json.collection do
  json.id @import.collection.id
  json.uri collection_url(@import.collection)
end

if @import.task
  json.task do
    json.id @import.task.id
    json.uri task_url(@import.task)
  end
end

json.user do
  json.id @import.user.id
  json.uri user_url(@import.user)
end
