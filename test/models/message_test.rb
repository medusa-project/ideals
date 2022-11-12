require 'test_helper'

class MessageTest < ActiveSupport::TestCase

  setup do
    clear_message_queues
  end

  teardown do
    clear_message_queues
  end

  # as_console()

  test "as_console() returns a correct value" do
    message = messages(:successful_ingest)
    assert_not_nil message.as_console
  end

  # label()

  test "label() returns a correct value" do
    message = messages(:ingest_no_response)
    assert_equal "#{message.operation} @ #{message.created_at}", message.label
  end

  # medusa_url()

  test "medusa_url() returns a URL when medusa_uuid is set" do
    message = Message.new
    message.medusa_uuid = SecureRandom.uuid
    assert_equal ::Configuration.instance.medusa[:base_url] + "/uuids/" + message.medusa_uuid,
                 message.medusa_url
  end

  test "medusa_url() returns nil when medusa_uuid is not set" do
    message = Message.new
    assert_nil message.medusa_url
  end

  # send_message()

  test "send_message() sends a correct ingest message" do
    @instance = messages(:ingest_no_response)
    @instance.send_message
    queue = @instance.bitstream.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_equal "ingest", message['operation']
      assert_equal "staging/cat", message['staging_key']
      assert_equal "target/cat", message['target_key']
      assert_equal @instance.bitstream.class.to_s, message['pass_through']['class']
      assert_equal @instance.bitstream.id, message['pass_through']['identifier']
    end
  end

  test "send_message() sends a correct delete message" do
    @instance = messages(:delete_no_response)
    @instance.send_message
    queue = @instance.bitstream.institution.outgoing_message_queue
    AmqpHelper::Connector[:ideals].with_parsed_message(queue) do |message|
      assert_equal "delete", message['operation']
      assert_equal "3d2a99d5-2f5b-401e-80c1-864a95e3acf7", message['uuid']
      assert_equal @instance.bitstream.class.to_s, message['pass_through']['class']
      assert_equal @instance.bitstream.id, message['pass_through']['identifier']
    end
  end

end
