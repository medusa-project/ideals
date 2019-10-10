require "rails_helper"

RSpec.describe HandlesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/handles").to route_to("handles#index")
    end

    it "routes to #new" do
      expect(:get => "/handles/new").to route_to("handles#new")
    end

    it "routes to #show" do
      expect(:get => "/handles/1").to route_to("handles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/handles/1/edit").to route_to("handles#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/handles").to route_to("handles#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/handles/1").to route_to("handles#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/handles/1").to route_to("handles#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/handles/1").to route_to("handles#destroy", :id => "1")
    end
  end
end
