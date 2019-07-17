# frozen_string_literal: true

require "rails_helper"

RSpec.describe "InviteeNotes", type: :petition do
  describe "GET /invitee_notes" do
    it "works! (now write some real specs)" do
      get invitee_notes_path
      expect(response).to have_http_status(200)
    end
  end
end
