# frozen_string_literal: true

json.set! "class", @bitstream.class.to_s
json.uri item_bitstream_url(@bitstream.item, @bitstream, format: :json)
json.object_uri item_bitstream_object_url(@bitstream.item, @bitstream)

json.extract! @bitstream, :id, :length, :media_type, :filename,
              :original_filename, :bundle_position, :primary, :description,
              :created_at, :updated_at

if policy(@bitstream).create?
  json.presigned_upload_url @bitstream.presigned_upload_url
end

json.bundle Bitstream::Bundle.label(@bitstream.bundle)

json.item do
  json.id @bitstream.item.id
  json.uri item_url(@bitstream.item)
end
