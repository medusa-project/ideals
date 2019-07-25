require 'rails_helper'

RSpec.describe "managers/new", type: :view do
  before(:each) do
    assign(:manager, Manager.new(
      :uid => "MyString",
      :provider => "MyString"
    ))
  end

  it "renders new manager form" do
    render

    assert_select "form[action=?][method=?]", managers_path, "post" do

      assert_select "input[name=?]", "manager[uid]"

      assert_select "input[name=?]", "manager[provider]"
    end
  end
end
