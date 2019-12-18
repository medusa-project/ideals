# frozen_string_literal: true

json.extract! item, :id, :title, :submitter_email, :submitter_auth_provider, :in_archive, :withdrawn, :collection_id, :discoverable, :created_at, :updated_at
json.url item_url(item, format: :json)
