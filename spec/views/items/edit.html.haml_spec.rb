require 'rails_helper'

RSpec.describe "items/edit", type: :view do
  before(:each) do
    @resource = assign(:item, Item.create!(
      :title => "MyString",
      :submitter_email => "MyString",
      :submitter_auth_provider => "",
      :in_archive => "",
      :withdrawn => "",
      :collection_id => "",
      :discoverable => false
    ))
  end

  it "renders the edit item form" do
    render

    assert_select "form[action=?][method=?]", item_path(@resource), "post" do

      assert_select "input[name=?]", "item[title]"

      assert_select "input[name=?]", "item[submitter_email]"

      assert_select "input[name=?]", "item[submitter_auth_provider]"

      assert_select "input[name=?]", "item[in_archive]"

      assert_select "input[name=?]", "item[withdrawn]"

      assert_select "input[name=?]", "item[collection_id]"

      assert_select "input[name=?]", "item[discoverable]"
    end
  end
end
