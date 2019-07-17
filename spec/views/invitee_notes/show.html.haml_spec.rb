# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitee_notes/show", type: :view do
  before(:each) do
    @invitee_note = assign(:invitee_note, InviteeNote.create!(
                                            invitee_id: 2,
                                            note:       "MyText",
                                            source:     "Source"
                                          ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Source/)
  end
end
