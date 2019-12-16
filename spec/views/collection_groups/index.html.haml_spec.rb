require 'rails_helper'

RSpec.describe "collection_groups/index", type: :view do
  before(:each) do
    assign(:collection_groups, [
      CollectionGroup.create!(
        :title => "Title",
        :group_id => 2,
        :parent_group_id => 3
      ),
      CollectionGroup.create!(
        :title => "Title",
        :group_id => 2,
        :parent_group_id => 3
      )
    ])
  end

  it "renders a list of collection_groups" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Group Type".to_s, :count => 2
  end
end
