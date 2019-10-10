require 'rails_helper'

RSpec.describe "handles/show", type: :view do
  before(:each) do
    @handle = assign(:handle, Handle.create!(
      :handle => "Handle",
      :resource_type_id => 2,
      :resource_id => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Handle/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
