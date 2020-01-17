# frozen_string_literal: true

json.extract! item, :id, :title, :submitter_email, :submitter_auth_provider, :in_archive, :withdrawn, :discoverable, :created_at, :updated_at
json.uri item_url(item, format: :json)
json.collection_uri collection_url(item.collection_id, format: :json)