# frozen_string_literal: true

json.set! "class", @item.class.to_s
json.uri item_url(@item, format: :json)

if policy(@item).show?
  json.extract! @item, :id, :exists_in_medusa?, :discoverable, :created_at, :updated_at
  json.stage Item::Stages.constants.find{ |c| @item.stage == c }&.to_s&.downcase&.capitalize
  if @item.primary_collection
    json.primary_collection do
      json.id @item.primary_collection.id
      json.uri collection_url(@item.primary_collection, format: :json)
    end
  end
  json.collections do
    @item.collection_ids.each do |collection_id|
      json.child! do
        json.id collection_id
        json.uri collection_url(collection_id, format: :json)
      end
    end
  end

  json.elements do
    @item.effective_metadata_profile.elements.each do |profile_element|
      matching_elements = @item.elements.select{ |e| e.name == profile_element.name }
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

  json.files do
    @item.bitstreams.order(:original_filename).each do |bitstream|
      json.child! do
        json.original_filename bitstream.original_filename
        json.media_type bitstream.media_type
        json.length bitstream.length
        json.uri item_bitstream_url(@item, bitstream)
      end
    end
  end
end