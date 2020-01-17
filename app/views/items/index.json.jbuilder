# frozen_string_literal: true

json.start @start
json.limit @limit
json.numResults @count
json.results do
  json.array! @items do |item|
    json.id item.id
    json.uri item_url(item, format: :json)
  end
end
