require 'rails_helper'

RSpec.describe "items/show", type: :view do
  before(:each) do
    @resource = assign(:item, Item.create!(
      :title => "Title",
      :submitter_email => "Submitter Email",
      :submitter_auth_provider => "",
      :in_archive => "",
      :withdrawn => "",
      :collection_id => "",
      :discoverable => false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Submitter Email/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/false/)
  end
end
