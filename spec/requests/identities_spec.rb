# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Identities", type: :petition do
  describe "GET /identities" do
    it "works! (now write some real specs)" do
      get identities_path
      expect(response).to have_http_status(200)
    end
  end
end
