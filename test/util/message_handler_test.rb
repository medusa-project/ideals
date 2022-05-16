require 'test_helper'

class MessageHandlerTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  # handle()

  test "handle() handles an ingest-succeeded message" do
    message          = messages(:ingest_no_response)
    bitstream        = bitstreams(:item1_in_staging)
    medusa_uuid      = SecureRandom.uuid
    incoming_message = {
        'status'       => "ok",
        'operation'    => "ingest",
        'staging_key'  => message.staging_key,
        'medusa_key'   => "cats",
        'uuid'         => medusa_uuid,
        'pass_through' => {
            'class'      => "Bitstream",
            'identifier' => bitstream.id
        }
    }
    MessageHandler.handle(JSON.generate(incoming_message))

    message = Message.order(updated_at: :desc).limit(1).first
    assert_equal "ok", message.status
    assert_not_nil message.response_time
    assert_equal incoming_message['staging_key'], message.staging_key
    assert_equal incoming_message['medusa_key'], message.medusa_key
    assert_equal incoming_message['uuid'], message.medusa_uuid

    bitstream.reload
    assert_equal medusa_uuid, bitstream.medusa_uuid
    assert_equal 'cats', bitstream.medusa_key
  end

  test "handle() handles an ingest-failed message" do
    message          = messages(:ingest_no_response)
    incoming_message = {
        'status'       => "error",
        'operation'    => "ingest",
        'error'        => "Something happened",
        'staging_key'  => message.staging_key,
        'pass_through' => {
            'class'      => "Bitstream",
            'identifier' => 99999
        }
    }
    MessageHandler.handle(JSON.generate(incoming_message))

    message = Message.order(updated_at: :desc).limit(1).first
    assert_equal "error", message.status
    assert_not_nil message.response_time
    assert_equal incoming_message['staging_key'], message.staging_key
    assert_equal incoming_message['error'], message.error_text
  end

  test "handle() handles a delete-succeeded message" do
    incoming_message = {
        'status'    => "ok",
        'operation' => "delete",
        'uuid'      => messages(:successful_delete).medusa_uuid
    }
    MessageHandler.handle(JSON.generate(incoming_message)) # assert no errors
  end

  test "handle() deletes any bitstream corresponding to a delete-succeeded message" do
    bitstream        = bitstreams(:item2_in_medusa)
    incoming_message = {
        'status'    => "ok",
        'operation' => "delete",
        'uuid'      => bitstream.medusa_uuid
    }
    MessageHandler.handle(JSON.generate(incoming_message))

    assert_raises ActiveRecord::RecordNotFound do
      bitstream.reload
    end
  end

  test "handle() handles a delete-failed message" do
    incoming_message = {
        'status'    => "error",
        'operation' => "delete",
        'uuid'      => messages(:failed_delete).medusa_uuid
    }
    MessageHandler.handle(JSON.generate(incoming_message))

    assert IdealsMailer.deliveries.any?
  end

  # valid?()

  test "valid?() returns true for a valid ingest-success message" do
    assert MessageHandler.valid?({
                                     "operation" => "ingest",
                                     "status" => "ok"
                                  })
  end

  test "valid?() returns true for a valid ingest-error message" do
    assert MessageHandler.valid?({
                                     "operation" => "ingest",
                                     "status" => "error"
                                  })
  end

  test "valid?() returns true for a valid delete-success message" do
    assert MessageHandler.valid?({
                                     "operation" => "delete",
                                     "status" => "ok"
                                  })
  end

  test "valid?() returns true for a valid delete-error message" do
    assert MessageHandler.valid?({
                                     "operation" => "delete",
                                     "status" => "error"
                                  })
  end

  test "valid?() returns false for an invalid message" do
    assert !MessageHandler.valid?({ "status" => "bogus" })
  end

end
