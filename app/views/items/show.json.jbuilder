# frozen_string_literal: true

json.set! "class", @resource.class.to_s
json.uri item_url(@resource, format: :json)

if policy(@resource).show?
  json.extract! @resource, :id, :in_archive, :withdrawn, :discoverable, :created_at, :updated_at
  json.primary_collection do
    json.id @resource.primary_collection_id
    json.uri collection_url(@resource.primary_collection_id, format: :json)
  end

  json.collections do
    @resource.collection_ids.each do |collection_id|
      json.child! do
        json.id collection_id
        json.uri collection_url(collection_id, format: :json)
      end
    end
  end

  json.elements do
    @resource.metadata_profile.elements.each do |profile_element|
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
end