require "rails_helper"

RSpec.describe ManagersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/managers").to route_to("managers#index")
    end

    it "routes to #new" do
      expect(:get => "/managers/new").to route_to("managers#new")
    end

    it "routes to #show" do
      expect(:get => "/managers/1").to route_to("managers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/managers/1/edit").to route_to("managers#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/managers").to route_to("managers#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/managers/1").to route_to("managers#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/managers/1").to route_to("managers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/managers/1").to route_to("managers#destroy", :id => "1")
    end
  end
end
