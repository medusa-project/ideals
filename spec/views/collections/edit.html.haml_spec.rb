require 'rails_helper'

RSpec.describe "collections/edit", type: :view do
  before(:each) do
    @resource = assign(:collection, Collection.create!(
      :title => "MyString",
      :description => "MyText"
    ))
  end

  it "renders the edit collection form" do
    render

    assert_select "form[action=?][method=?]", collection_path(@resource), "post" do

      assert_select "input[name=?]", "collection[title]"

      assert_select "textarea[name=?]", "collection[description]"
    end
  end
end
