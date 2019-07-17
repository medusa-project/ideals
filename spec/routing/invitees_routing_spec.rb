# frozen_string_literal: true

require "rails_helper"

RSpec.describe InviteesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/invitees").to route_to("invitees#index")
    end

    it "routes to #new" do
      expect(get: "/invitees/new").to route_to("invitees#new")
    end

    it "routes to #show" do
      expect(get: "/invitees/1").to route_to("invitees#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/invitees/1/edit").to route_to("invitees#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/invitees").to route_to("invitees#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/invitees/1").to route_to("invitees#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/invitees/1").to route_to("invitees#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/invitees/1").to route_to("invitees#destroy", id: "1")
    end
  end
end
