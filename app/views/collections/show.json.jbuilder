# frozen_string_literal: true

json.set! "class", @collection.class.to_s
json.uri collection_url(@collection, format: :json)
json.extract! @collection, :id, :created_at, :updated_at

json.primary_unit do
  json.id @collection.primary_unit_id
  json.uri unit_url(@collection.primary_unit_id, format: :json)
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

json.elements do
  @collection.effective_metadata_profile.elements.each do |profile_element|
    matching_elements = @collection.elements.select{ |e| e.name == profile_element.name }
    matching_elements.each do |element|
      json.child! do
        json.name element.name
        json.label element.label
        json.uri element.registered_element.uri
        json.string_value sanitize(element.string)
        json.uri_value element.uri
      end
    end
  end
end