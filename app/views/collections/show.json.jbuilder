# frozen_string_literal: true

json.set! "class", @collection.class.to_s
json.uri collection_url(@collection, format: :json)
json.extract! @collection, :id, :title, :description, :short_description, :introduction, :rights, :created_at, :updated_at

json.primary_unit do
  json.id @collection.primary_unit.id
  json.uri unit_url(@collection.primary_unit.id, format: :json)
end
json.units do
  @collection.unit_ids.each do |unit_id|
    json.child! do
      json.id unit_id
      json.uri unit_url(unit_id, format: :json)
    end
  end
end

if @collection.parent
  json.parent do
    json.id @collection.parent.id
    json.uri collection_url(@collection.parent)
  end
end

if @collection.collections.any?
  json.children @collection.collections do |child|
    json.id child.id
    json.uri collection_url(child)
  end
end
