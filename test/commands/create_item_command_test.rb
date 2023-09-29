require 'test_helper'

class CreateItemCommandTest < ActiveSupport::TestCase

  test "execute() returns the expected instance" do
    submitter   = users(:southwest_sysadmin)
    collection  = collections(:uiuc_collection1)
    institution = collection.institution
    command     = CreateItemCommand.new(submitter:          submitter,
                                        institution:        institution,
                                        primary_collection: collection)
    item = command.execute

    assert_equal submission_profile_elements(:uiuc_default_description).placeholder_text,
                 item.element("dc:description").string
    assert_equal submission_profile_elements(:uiuc_default_subject).placeholder_text,
                 item.element("dc:subject").string
    assert_equal Item::Stages::SUBMITTING, item.stage
    assert_equal institution, item.institution
    assert_equal institution.deposit_agreement, item.deposit_agreement
  end

  test "execute() creates an associated Event" do
    Event.destroy_all

    submitter   = users(:southwest_sysadmin)
    collection  = collections(:uiuc_collection1)
    institution = collection.institution
    command     = CreateItemCommand.new(submitter:          submitter,
                                        institution:        institution,
                                        primary_collection: collection)
    item = command.execute

    event = Event.all.first
    assert_equal Event::Type::CREATE, event.event_type
    assert_equal item, event.item
    assert_equal submitter, event.user
    assert_equal item.as_change_hash, event.after_changes
  end

end
