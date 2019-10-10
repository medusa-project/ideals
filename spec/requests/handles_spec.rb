require 'rails_helper'

RSpec.describe "Handles", type: :request do
  describe "GET /handles" do
    it "works! (now write some real specs)" do
      get handles_path
      expect(response).to have_http_status(200)
    end
  end
end
