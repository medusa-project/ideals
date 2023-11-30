# frozen_string_literal: true

json.start @start
json.window @window
json.numResults @count
json.results do
  json.array! @items do |entity|
    json.id entity.id
    json.uri polymorphic_url(entity, format: :json)
  end
end
