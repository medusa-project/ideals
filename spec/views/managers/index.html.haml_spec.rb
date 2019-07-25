require 'rails_helper'

RSpec.describe "managers/index", type: :view do
  before(:each) do
    assign(:managers, [
      Manager.create!(
        :uid => "Uid",
        :provider => "Provider"
      ),
      Manager.create!(
        :uid => "Uid",
        :provider => "Provider"
      )
    ])
  end

  it "renders a list of managers" do
    render
    assert_select "tr>td", :text => "Uid".to_s, :count => 2
    assert_select "tr>td", :text => "Provider".to_s, :count => 2
  end
end
