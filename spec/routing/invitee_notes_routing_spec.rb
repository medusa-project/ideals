# frozen_string_literal: true

require "rails_helper"

RSpec.describe InviteeNotesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/invitee_notes").to route_to("invitee_notes#index")
    end

    it "routes to #new" do
      expect(get: "/invitee_notes/new").to route_to("invitee_notes#new")
    end

    it "routes to #show" do
      expect(get: "/invitee_notes/1").to route_to("invitee_notes#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/invitee_notes/1/edit").to route_to("invitee_notes#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/invitee_notes").to route_to("invitee_notes#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/invitee_notes/1").to route_to("invitee_notes#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/invitee_notes/1").to route_to("invitee_notes#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/invitee_notes/1").to route_to("invitee_notes#destroy", id: "1")
    end
  end
end
