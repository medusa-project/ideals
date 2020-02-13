# frozen_string_literal: true

json.start @start
json.window @window
json.numResults @count
json.results do
  json.array! @units do |unit|
    json.id unit.id
    json.uri unit_url(unit, format: :json)
  end
end
