# frozen_string_literal: true

json.set! "class", @unit.class.to_s
json.uri unit_url(@unit, format: :json)
json.extract! @unit, :id, :created_at, :updated_at, :title

if @unit.parent_id
  json.parent do
    json.id @unit.parent_id
    json.uri unit_url(@unit.parent_id, format: :json)
  end
end
json.children do
  @unit.unit_ids.each do |unit_id|
    json.child! do
      json.id unit_id
      json.uri unit_url(unit_id, format: :json)
    end
  end
end
json.collections do
  @unit.collections.each do |collection|
    json.child! do
      json.id collection.id
      json.uri collection_url(collection, format: :json)
    end
  end
end