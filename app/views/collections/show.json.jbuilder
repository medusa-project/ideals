# frozen_string_literal: true

json.set! "class", @resource.class.to_s
json.uri collection_url(@resource, format: :json)
json.extract! @resource, :id, :created_at, :updated_at

json.primary_unit do
  json.id @resource.primary_unit_id
  json.uri unit_url(@resource.primary_unit_id, format: :json)
end
json.units do
  @resource.unit_ids.each do |unit_id|
    json.child! do
      json.id unit_id
      json.uri unit_url(unit_id, format: :json)
    end
  end
end

json.elements do
  @resource.effective_metadata_profile.elements.each do |profile_element|
    matching_elements = @resource.elements.select{ |e| e.name == profile_element.name }
    matching_elements.each do |element|
      json.child! do
        json.name element.name
        json.label element.label
        json.uri element.uri
        json.string_value sanitize(element.string)
      end
    end
  end
end