# frozen_string_literal: true

require "rails_helper"

RSpec.describe "identities/index", type: :view do
  before(:each) do
    assign(:identities, [
             Identity.create!(
               name:              "Name",
               email:             "Email",
               password_digest:   "Password Digest",
               activation_digest: "Activation Digest",
               activated:         false,
               reset_digest:      "Reset Digest",
               invitee_id:        2
             ),
             Identity.create!(
               name:              "Name",
               email:             "Email",
               password_digest:   "Password Digest",
               activation_digest: "Activation Digest",
               activated:         false,
               reset_digest:      "Reset Digest",
               invitee_id:        2
             )
           ])
  end

  it "renders a list of identities" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "Email".to_s, count: 2
    assert_select "tr>td", text: "Password Digest".to_s, count: 2
    assert_select "tr>td", text: "Activation Digest".to_s, count: 2
    assert_select "tr>td", text: false.to_s, count: 2
    assert_select "tr>td", text: "Reset Digest".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
  end
end
