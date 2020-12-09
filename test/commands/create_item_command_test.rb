require 'test_helper'

class CreateItemCommandTest < ActiveSupport::TestCase

  test "execute() returns the expected instance" do
    submitter  = users(:admin)
    collection = collections(:collection1)
    command    = CreateItemCommand.new(submitter:             submitter,
                                       primary_collection_id: collection.id)
    item = command.execute

    assert_equal submission_profile_elements(:default_description).placeholder_text,
                 item.element("dc:description").string
    assert_equal submission_profile_elements(:default_subject).placeholder_text,
                 item.element("dc:subject").string
    assert_equal Item::Stages::SUBMITTING, item.stage
  end

  test "execute() creates an associated Event" do
    Event.destroy_all

    submitter = users(:admin)
    command   = CreateItemCommand.new(submitter:             submitter,
                                      primary_collection_id: collections(:collection1).id)
    item = command.execute

    event = Event.all.first
    assert_equal Event::Type::CREATE, event.event_type
    assert_equal item, event.item
    assert_equal submitter, event.user
    assert_equal item.as_change_hash, event.after_changes
  end

end
