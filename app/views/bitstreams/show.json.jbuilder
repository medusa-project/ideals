# frozen_string_literal: true

json.set! "class", @bitstream.class.to_s
json.uri item_bitstream_url(@bitstream.item, @bitstream, format: :json)
json.data_uri item_bitstream_data_url(@bitstream.item, @bitstream)

json.extract! @bitstream, :id, :length, :media_type, :original_filename,
              :exists_in_staging, :staging_key, :medusa_key, :medusa_uuid,
              :created_at, :updated_at

json.item do
  json.id @bitstream.item.id
  json.uri item_url(@bitstream.item)
end
