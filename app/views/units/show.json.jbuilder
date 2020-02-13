# frozen_string_literal: true

json.set! "class", @resource.class.to_s
json.uri unit_url(@resource, format: :json)
json.extract! @resource, :id, :created_at, :updated_at, :title

if @resource.parent_id
  json.parent do
    json.id @resource.parent_id
    json.uri unit_url(@resource.parent_id, format: :json)
  end
end
json.children do
  @resource.unit_ids.each do |unit_id|
    json.child! do
      json.id unit_id
      json.uri unit_url(unit_id, format: :json)
    end
  end
end
json.collections do
  @resource.all_collections.each do |collection|
    json.child! do
      json.id collection.id
      json.uri collection_url(collection, format: :json)
    end
  end
end