# frozen_string_literal: true

json.results do
  json.array! @submittable_collections do |collection|
    json.id collection.id
    json.uri collection_url(collection, format: :json)
    json.title collection.title
  end
end
