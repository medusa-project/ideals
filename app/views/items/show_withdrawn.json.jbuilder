# frozen_string_literal: true

json.set! "class", @item.class.to_s
json.uri item_url(@item, format: :json)

if policy(@item).show?
  json.extract! @item, :id, :exists_in_medusa?, :discoverable, :created_at, :updated_at
  json.stage Item::Stages.label_for(@item.stage)
  json.stage_reason @item.stage_reason
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

end