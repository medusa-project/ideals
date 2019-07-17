# frozen_string_literal: true

class InviteeNote < ApplicationRecord
  belongs_to :invitee, inverse_of: :invitee_notes
end
