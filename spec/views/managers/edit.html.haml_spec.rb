require 'rails_helper'

RSpec.describe "managers/edit", type: :view do
  before(:each) do
    @manager = assign(:manager, Manager.create!(
      :uid => "MyString",
      :provider => "MyString"
    ))
  end

  it "renders the edit manager form" do
    render

    assert_select "form[action=?][method=?]", manager_path(@manager), "post" do

      assert_select "input[name=?]", "manager[uid]"

      assert_select "input[name=?]", "manager[provider]"
    end
  end
end
