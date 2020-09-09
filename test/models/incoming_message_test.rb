require 'test_helper'

class IncomingMessageTest < ActiveSupport::TestCase

  # handle()

  test "handle() handles an ingest-succeeded message" do
    IncomingMessage.destroy_all
    ingest      = medusa_ingests(:one)
    bitstream   = bitstreams(:item1_jpg)
    medusa_uuid = SecureRandom.uuid
    medusa_message = {
        'status'       => "ok",
        'operation'    => "ingest",
        'staging_key'  => ingest.staging_key,
        'medusa_key'   => "cats",
        'uuid'         => medusa_uuid,
        'pass_through' => {
            'class'      => "Bitstream",
            'identifier' => bitstream.id
        }
    }
    IncomingMessage.handle(JSON.generate(medusa_message))

    message = IncomingMessage.limit(1).first
    assert_equal "ok", message.status
    assert_equal medusa_message['staging_key'], message.staging_key
    assert_equal medusa_message['medusa_key'], message.medusa_key
    assert_equal medusa_message['uuid'], message.uuid

    ingest.reload
    assert_equal medusa_message['status'], ingest.request_status
    assert_equal medusa_message['medusa_key'], ingest.medusa_path
    assert_equal medusa_message['uuid'], ingest.medusa_uuid
    assert_not_nil ingest.response_time

    bitstream.reload
    assert_equal medusa_uuid, bitstream.medusa_uuid
    assert_equal 'cats', bitstream.medusa_key
  end

  test "handle() handles an ingest-failed message" do
    IncomingMessage.destroy_all
    ingest         = medusa_ingests(:one)
    medusa_message = {
        'status'       => "error",
        'operation'    => "ingest",
        'error'        => "Something happened",
        'staging_key'  => ingest.staging_key,
        'pass_through' => {
            'class'      => "Bitstream",
            'identifier' => 99999
        }
    }
    IncomingMessage.handle(JSON.generate(medusa_message))

    message = IncomingMessage.limit(1).first
    assert_equal "error", message.status
    assert_equal medusa_message['staging_key'], message.staging_key

    ingest.reload
    assert_equal medusa_message['status'], ingest.request_status
    assert_equal medusa_message['error'], ingest.error_text
    assert_not_nil ingest.response_time

    assert IdealsMailer.deliveries.any?
  end

  test "handle() handles a delete-succeeded message" do
    medusa_message = {
        'status'    => "ok",
        'operation' => "delete",
        'uuid'      => SecureRandom.uuid
    }
    IncomingMessage.handle(JSON.generate(medusa_message)) # assert no errors
  end

  test "handle() deletes any bitstream corresponding to a delete-succeeded message" do
    bitstream = bitstreams(:item1_in_medusa)
    medusa_message = {
        'status'    => "ok",
        'operation' => "delete",
        'uuid'      => bitstream.medusa_uuid
    }
    IncomingMessage.handle(JSON.generate(medusa_message))

    assert_raises ActiveRecord::RecordNotFound do
      bitstream.reload
    end
  end

  test "handle() handles a delete-failed message" do
    medusa_message = {
        'status'    => "error",
        'operation' => "delete",
        'uuid'      => SecureRandom.uuid
    }
    IncomingMessage.handle(JSON.generate(medusa_message))

    assert IdealsMailer.deliveries.any?
  end

  # valid?()

  test "valid?() returns true for a valid ingest-success message" do
    assert IncomingMessage.valid?({
                                      "operation" => "ingest",
                                      "status" => "ok"
                                  })
  end

  test "valid?() returns true for a valid ingest-error message" do
    assert IncomingMessage.valid?({
                                      "operation" => "ingest",
                                      "status" => "error"
                                  })
  end

  test "valid?() returns true for a valid delete-success message" do
    assert IncomingMessage.valid?({
                                      "operation" => "delete",
                                      "status" => "ok"
                                  })
  end

  test "valid?() returns true for a valid delete-error message" do
    assert IncomingMessage.valid?({
                                      "operation" => "delete",
                                      "status" => "error"
                                  })
  end

  test "valid?() returns false for an invalid message" do
    hash = { "status" => "bogus" }
    assert !IncomingMessage.valid?(hash)
  end

end
