# frozen_string_literal: true

require "rails_helper"

RSpec.describe "invitees/show", type: :view do
  before(:each) do
    @invitee = assign(:invitee, Invitee.create!(
                                  email:          "Email",
                                  role:           "Role",
                                  expires_at:     "",
                                  approval_state: Ideals::ApprovalState::PENDING
                                ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Role/)
    expect(rendered).to match(//)
    expect(rendered).to match(/false/)
  end
end
