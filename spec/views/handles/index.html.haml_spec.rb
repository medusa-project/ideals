require 'rails_helper'

RSpec.describe "handles/index", type: :view do
  before(:each) do
    assign(:handles, [
      Handle.create!(
        :handle => "Handle",
        :resource_type_id => 2,
        :resource_id => 3
      ),
      Handle.create!(
        :handle => "Handle",
        :resource_type_id => 2,
        :resource_id => 3
      )
    ])
  end

  it "renders a list of handles" do
    render
    assert_select "tr>td", :text => "Handle".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end
