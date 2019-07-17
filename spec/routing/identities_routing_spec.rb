# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdentitiesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/identities").to route_to("identities#index")
    end

    it "routes to #new" do
      expect(get: "/identities/new").to route_to("identities#new")
    end

    it "routes to #show" do
      expect(get: "/identities/1").to route_to("identities#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/identities/1/edit").to route_to("identities#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/identities").to route_to("identities#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/identities/1").to route_to("identities#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/identities/1").to route_to("identities#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/identities/1").to route_to("identities#destroy", id: "1")
    end
  end
end
