require 'rails_helper'

RSpec.describe "items/new", type: :view do
  before(:each) do
    assign(:item, Item.new(
      :title => "MyString",
      :submitter_email => "MyString",
      :submitter_auth_provider => "",
      :in_archive => "",
      :withdrawn => "",
      :collection_id => "",
      :discoverable => false
    ))
  end

  it "renders new item form" do
    render

    assert_select "form[action=?][method=?]", items_path, "post" do

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
