# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitees/new", type: :view do
  before(:each) do
    assign(:invitee, Invitee.new(
                       email:          "MyString",
                       role:           "MyString",
                       expires_at:     "",
                       approval_state: Ideals::ApprovalState::PENDING
                     ))
  end

  it "renders new invitee form" do
    render

    assert_select "form[action=?][method=?]", invitees_path, "post" do
      assert_select "input[name=?]", "invitee[email]"

      assert_select "input[name=?]", "invitee[role]"

      assert_select "input[name=?]", "invitee[expires_at]"

      assert_select "input[name=?]", "invitee[approval_state]"
    end
  end
end
