# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitee_notes/new", type: :view do
  before(:each) do
    assign(:invitee_note, InviteeNote.new(
                            invitee_id: 1,
                            note:       "MyText",
                            source:     "MyString"
                          ))
  end

  it "renders new invitee_note form" do
    render

    assert_select "form[action=?][method=?]", invitee_notes_path, "post" do
      assert_select "input[name=?]", "invitee_note[invitee_id]"

      assert_select "textarea[name=?]", "invitee_note[note]"

      assert_select "input[name=?]", "invitee_note[source]"
    end
  end
end
