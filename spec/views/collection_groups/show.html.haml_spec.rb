require 'rails_helper'

RSpec.describe "collection_groups/show", type: :view do
  before(:each) do
    @resource = assign(:collection_group, CollectionGroup.create!(
      :title => "Title",
      :group_id => 2,
      :parent_group_id => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Group Type/)
  end
end
