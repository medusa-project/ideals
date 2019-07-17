# frozen_string_literal: true

json.extract! identity, :id, :name, :email, :password_digest, :activation_digest, :activated, :activated_at, :reset_digest, :invitee_id, :reset_sent_at, :created_at, :updated_at
json.url identity_url(identity, format: :json)
