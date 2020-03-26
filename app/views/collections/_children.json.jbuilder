json.array! @collections do |collection|
  json.class       collection.class.to_s
  json.id          collection.id
  json.title       collection.title
  json.uri         collection_url(collection)
  json.numChildren collection.collections.length
end
