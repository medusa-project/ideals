require "rails_helper"

RSpec.describe CollectionGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/collection_groups").to route_to("collection_groups#index")
    end

    it "routes to #new" do
      expect(:get => "/collection_groups/new").to route_to("collection_groups#new")
    end

    it "routes to #show" do
      expect(:get => "/collection_groups/1").to route_to("collection_groups#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/collection_groups/1/edit").to route_to("collection_groups#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/collection_groups").to route_to("collection_groups#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/collection_groups/1").to route_to("collection_groups#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/collection_groups/1").to route_to("collection_groups#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/collection_groups/1").to route_to("collection_groups#destroy", :id => "1")
    end
  end
end
