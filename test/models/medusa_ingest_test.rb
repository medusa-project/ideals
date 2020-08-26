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
        "staging_key"   => medusa_ingests(:one).staging_key,
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
        "staging_key" => medusa_ingests(:one).staging_key
    }
    MedusaIngest.on_medusa_message(JSON.generate(hash))

    response = IngestResponse.limit(1).first
    assert_equal hash['status'], response.status

    ingest = MedusaIngest.
        where(staging_key: hash["staging_key"]).
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

end
