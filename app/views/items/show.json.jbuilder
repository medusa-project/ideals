# frozen_string_literal: true

json.set! "class", @item.class.to_s
json.uri item_url(@item, format: :json)

if policy(@item).show?
  json.extract! @item, :id, :exists_in_medusa?, :created_at, :updated_at
  json.stage Item::Stages.label_for(@item.stage)
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
          json.dublin_core_mapping element.registered_element.dublin_core_mapping
          json.string_value element.string
          json.uri_value element.uri
        end
      end
    end
  end

  json.files do
    @item.bitstreams.order(:filename).each do |bitstream|
      json.child! do
        json.filename bitstream.filename
        json.media_type bitstream.media_type
        json.length bitstream.length
        json.uri item_bitstream_url(@item, bitstream)
      end
    end
  end
end