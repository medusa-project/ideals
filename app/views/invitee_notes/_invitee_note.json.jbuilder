# frozen_string_literal: true

json.extract! invitee_note, :id, :invitee_id, :note, :source, :created_at, :updated_at
json.url invitee_note_url(invitee_note, format: :json)
