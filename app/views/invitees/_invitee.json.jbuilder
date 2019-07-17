# frozen_string_literal: true

json.extract! invitee, :id, :email, :role, :expires_at, :approved, :created_at, :updated_at
json.url invitee_url(invitee, format: :json)
