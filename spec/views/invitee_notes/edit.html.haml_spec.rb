# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitee_notes/edit", type: :view do
  before(:each) do
    @invitee_note = assign(:invitee_note, InviteeNote.create!(
                                            invitee_id: 1,
                                            note:       "MyText",
                                            source:     "MyString"
                                          ))
  end

  it "renders the edit invitee_note form" do
    render

    assert_select "form[action=?][method=?]", invitee_note_path(@invitee_note), "post" do
      assert_select "input[name=?]", "invitee_note[invitee_id]"

      assert_select "textarea[name=?]", "invitee_note[note]"

      assert_select "input[name=?]", "invitee_note[source]"
    end
  end
end
