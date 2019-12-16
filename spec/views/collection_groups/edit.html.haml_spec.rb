require 'rails_helper'

RSpec.describe "collection_groups/edit", type: :view do
  before(:each) do
    @resource = assign(:collection_group, CollectionGroup.create!(
      :title => "MyString",
      :group_id => 1,
      :parent_group_id => 1
    ))
  end

  it "renders the edit collection_group form" do
    render

    assert_select "form[action=?][method=?]", collection_group_path(@resource), "post" do

      assert_select "input[name=?]", "collection_group[title]"

      assert_select "input[name=?]", "collection_group[group_id]"

      assert_select "input[name=?]", "collection_group[parent_group_id]"

    end
  end
end
