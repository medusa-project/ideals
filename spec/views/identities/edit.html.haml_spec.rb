# frozen_string_literal: true

require "rails_helper"

RSpec.describe "identities/edit", type: :view do
  before(:each) do
    @identity = assign(:identity, Identity.create!(
                                    name:              "MyString",
                                    email:             "MyString",
                                    password_digest:   "MyString",
                                    activation_digest: "MyString",
                                    activated:         false,
                                    reset_digest:      "MyString",
                                    invitee_id:        1
                                  ))
  end

  it "renders the edit identity form" do
    render

    assert_select "form[action=?][method=?]", identity_path(@identity), "post" do
      assert_select "input[name=?]", "identity[name]"

      assert_select "input[name=?]", "identity[email]"

      assert_select "input[name=?]", "identity[password_digest]"

      assert_select "input[name=?]", "identity[activation_digest]"

      assert_select "input[name=?]", "identity[activated]"

      assert_select "input[name=?]", "identity[reset_digest]"

      assert_select "input[name=?]", "identity[invitee_id]"
    end
  end
end
