require 'test_helper'

class MedusaIngestTest < ActiveSupport::TestCase

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(MedusaIngest.outgoing_queue)
  end

  test "incoming_queue() returns the incoming queue" do
    assert_equal ::Configuration.instance.medusa[:incoming_queue],
                 MedusaIngest.incoming_queue
  end

  test "message_valid?() returns true for a valid message" do
    hash = { "status" => "ok" }
    assert MedusaIngest.message_valid?(hash)
    hash = { "status" => "error" }
    assert MedusaIngest.message_valid?(hash)
  end

  test "message_valid?() returns false for an invalid message" do
    hash = { "status" => "bogus" }
    assert !MedusaIngest.message_valid?(hash)
  end

  test "on_medusa_message() creates an IngestResponse for a succeeded message" do
    skip # TODO: fix this
    IngestResponse.destroy_all
    hash = {
        "status"        => "ok",
        "response_time" => Time.current.iso8601,
        "staging_key"   => medusa_ingests(:one).staging_path,
        "medusa_key"    => "cats",
        "uuid"          => SecureRandom.uuid
    }
    MedusaIngest.on_medusa_message(JSON.generate(hash))

    response = IngestResponse.limit(1).first
    assert_equal hash['status'], response.status
    assert_equal hash['response_time'], response.response_time.iso8601
    assert_equal hash['staging_key'], response.staging_key
    assert_equal hash['medusa_key'], response.medusa_key
    assert_equal hash['uuid'], response.uuid

    ingest = MedusaIngest.where(staging_key: hash["staging_key"]).limit(1).first
    assert_equal hash['medusa_key'], ingest.medusa_key
    assert_equal hash['uuid'], ingest.medusa_uuid
    assert_equal hash['status'], ingest.request_status
    assert_not_nil ingest.response_time

    # TODO: test the bitstream
  end

  test "on_medusa_message() creates an IngestResponse for a failed message" do
    skip # TODO: fix this
    IngestResponse.destroy_all
    hash = {
        "status"       => "error",
        "error"        => "something happened",
        "staging_path" => medusa_ingests(:one).staging_path
    }
    MedusaIngest.on_medusa_message(JSON.generate(hash))

    response = IngestResponse.limit(1).first
    assert_equal hash['status'], response.status

    ingest = MedusaIngest.
        where(staging_path: hash["staging_path"]).
        order(created_at: :desc).
        limit(1).first
    assert_equal hash['status'], ingest.request_status
    assert_equal hash['error'], ingest.error_text
    assert_not_nil ingest.response_time

    assert IdealsMailer.deliveries.any?
  end

  test "outgoing_queue() returns the outgoing queue" do
    assert_equal ::Configuration.instance.medusa[:outgoing_queue],
                 MedusaIngest.outgoing_queue
  end

  test "send_bitstream_to_medusa() raises an error if the bitstream does not
  have an ID" do
    bitstream = Bitstream.new(staging_key: "cats", medusa_uuid: "cats")
    assert_raises ArgumentError do
      MedusaIngest.send_bitstream_to_medusa(bitstream, "target_key")
    end
  end

  test "send_bitstream_to_medusa() raises an error if the bitstream does not
  have a staging key" do
    bitstream = Bitstream.new(medusa_uuid: "cats")
    assert_raises ArgumentError do
      MedusaIngest.send_bitstream_to_medusa(bitstream, "target_key")
    end
  end

  test "send_bitstream_to_medusa() raises an error if the bitstream has a
  Medusa UUID" do
    bitstream = bitstreams(:item1_jpg)
    bitstream.medusa_uuid = SecureRandom.uuid
    assert_raises AlreadyExistsError do
      MedusaIngest.send_bitstream_to_medusa(bitstream, "target_key")
    end
  end

  test "send_bitstream_to_medusa() sends a correct message" do
    bitstream = bitstreams(:item1_jpg)
    MedusaIngest.send_bitstream_to_medusa(bitstream, "target_key")

    AmqpHelper::Connector[:ideals].with_parsed_message(MedusaIngest.outgoing_queue) do |message|
      expected = {
          operation:    "ingest",
          staging_key:  bitstream.staging_key,
          target_key:   "target_key",
          pass_through: {
              class:      Bitstream.to_s,
              identifier: "#{bitstream.id}"
          }
      }.deep_stringify_keys
      assert_equal expected, message
    end
  end

end
