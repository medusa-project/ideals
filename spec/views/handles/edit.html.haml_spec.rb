require 'rails_helper'

RSpec.describe "handles/edit", type: :view do
  before(:each) do
    @handle = assign(:handle, Handle.create!(
      :handle => "MyString",
      :resource_type_id => 1,
      :resource_id => 1
    ))
  end

  it "renders the edit handle form" do
    render

    assert_select "form[action=?][method=?]", handle_path(@handle), "post" do

      assert_select "input[name=?]", "handle[handle]"

      assert_select "input[name=?]", "handle[resource_type_id]"

      assert_select "input[name=?]", "handle[resource_id]"
    end
  end
end
