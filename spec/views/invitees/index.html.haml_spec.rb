# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitees/index", type: :view do
  before(:each) do
    assign(:invitees, [
             Invitee.create!(
               email:      "Email",
               role:       "Role",
               expires_at: "",
               approved:   false
             ),
             Invitee.create!(
               email:      "Email",
               role:       "Role",
               expires_at: "",
               approved:   false
             )
           ])
  end

  it "renders a list of invitees" do
    render
    assert_select "tr>td", text: "Email".to_s, count: 2
    assert_select "tr>td", text: "Role".to_s, count: 2
    assert_select "tr>td", text: "".to_s, count: 2
    assert_select "tr>td", text: false.to_s, count: 2
  end
end
