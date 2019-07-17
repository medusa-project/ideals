# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitee_notes/index", type: :view do
  before(:each) do
    assign(:invitee_notes, [
             InviteeNote.create!(
               invitee_id: 2,
               note:       "MyText",
               source:     "Source"
             ),
             InviteeNote.create!(
               invitee_id: 2,
               note:       "MyText",
               source:     "Source"
             )
           ])
  end

  it "renders a list of invitee_notes" do
    render
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
    assert_select "tr>td", text: "Source".to_s, count: 2
  end
end
