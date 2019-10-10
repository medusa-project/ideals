require 'rails_helper'

RSpec.describe "handles/new", type: :view do
  before(:each) do
    assign(:handle, Handle.new(
      :handle => "MyString",
      :resource_type_id => 1,
      :resource_id => 1
    ))
  end

  it "renders new handle form" do
    render

    assert_select "form[action=?][method=?]", handles_path, "post" do

      assert_select "input[name=?]", "handle[handle]"

      assert_select "input[name=?]", "handle[resource_type_id]"

      assert_select "input[name=?]", "handle[resource_id]"
    end
  end
end
