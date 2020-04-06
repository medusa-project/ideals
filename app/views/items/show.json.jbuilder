# frozen_string_literal: true

json.set! "class", @resource.class.to_s
json.uri item_url(@resource, format: :json)

if policy(@resource).show?
  json.extract! @resource, :id, :submitting, :in_archive, :discoverable, :withdrawn, :created_at, :updated_at
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
          json.uri element.registered_element.uri
          json.string_value sanitize(element.string)
          json.uri_value element.uri
        end
      end
    end
  end

  json.bitstreams do
    @resource.bitstreams.order(:original_filename).each do |bitstream|
      json.child! do
        json.original_filename bitstream.original_filename
        json.media_type bitstream.media_type
        json.length bitstream.length
        json.uri item_bitstream_url(@resource, bitstream)
      end
    end
  end
end