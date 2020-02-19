# frozen_string_literal: true

# N.B.: this is not a public view and for the moment it exists only to drive
# various user autocomplete fields.

json.start @start
json.window @window
json.numResults @count
json.results do
  json.array! @users do |user|
    json.id user.id
    json.uri user_url(user)
    json.uid user.uid
    json.username user.username
    json.name user.name
    json.email user.email
  end
end
