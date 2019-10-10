require 'rails_helper'

RSpec.describe "CollectionGroups", type: :request do
  describe "GET /collection_groups" do
    it "works! (now write some real specs)" do
      get collection_groups_path
      expect(response).to have_http_status(200)
    end
  end
end
