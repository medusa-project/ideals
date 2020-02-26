# frozen_string_literal: true

json.start @start
json.window @window
json.numResults @count
json.results do
  json.array! @collections do |collection|
    json.id collection.id
    json.uri collection_url(collection, format: :json)
  end
end
