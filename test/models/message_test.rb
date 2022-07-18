require 'test_helper'

class MessageTest < ActiveSupport::TestCase

  setup do
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
  end

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(Message.outgoing_queue)
  end

  # incoming_queue()

  test "incoming_queue() returns the incoming queue" do
    assert_equal ::Configuration.instance.medusa[:incoming_queue],
                 Message.incoming_queue
  end

  # outgoing_queue()

  test "outgoing_queue() returns the outgoing queue" do
    assert_equal ::Configuration.instance.medusa[:outgoing_queue],
                 Message.outgoing_queue
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
    AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
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
    AmqpHelper::Connector[:ideals].with_parsed_message(Message.outgoing_queue) do |message|
      assert_equal "delete", message['operation']
      assert_equal "3d2a99d5-2f5b-401e-80c1-864a95e3acf7", message['uuid']
      assert_equal @instance.bitstream.class.to_s, message['pass_through']['class']
      assert_equal @instance.bitstream.id, message['pass_through']['identifier']
    end
  end

end
