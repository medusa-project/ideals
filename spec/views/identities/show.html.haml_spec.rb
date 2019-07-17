# frozen_string_literal: true

require "rails_helper"

RSpec.describe "identities/show", type: :view do
  before(:each) do
    @identity = assign(:identity, Identity.create!(
                                    name:              "Name",
                                    email:             "Email",
                                    password_digest:   "Password Digest",
                                    activation_digest: "Activation Digest",
                                    activated:         false,
                                    reset_digest:      "Reset Digest",
                                    invitee_id:        2
                                  ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Password Digest/)
    expect(rendered).to match(/Activation Digest/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Reset Digest/)
    expect(rendered).to match(/2/)
  end
end
