require 'rails_helper'

RSpec.describe "managers/show", type: :view do
  before(:each) do
    @manager = assign(:manager, Manager.create!(
      :uid => "Uid",
      :provider => "Provider"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Uid/)
    expect(rendered).to match(/Provider/)
  end
end
