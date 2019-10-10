require 'rails_helper'

RSpec.describe "items/index", type: :view do
  before(:each) do
    assign(:items, [
      Item.create!(
        :title => "Title",
        :submitter_email => "Submitter Email",
        :submitter_auth_provider => "",
        :in_archive => "",
        :withdrawn => "",
        :collection_id => "",
        :discoverable => false
      ),
      Item.create!(
        :title => "Title",
        :submitter_email => "Submitter Email",
        :submitter_auth_provider => "",
        :in_archive => "",
        :withdrawn => "",
        :collection_id => "",
        :discoverable => false
      )
    ])
  end

  it "renders a list of items" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Submitter Email".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
