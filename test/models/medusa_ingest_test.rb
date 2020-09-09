require 'test_helper'

class MedusaIngestTest < ActiveSupport::TestCase

  teardown do
    AmqpHelper::Connector[:ideals].clear_queues(MedusaIngest.outgoing_queue)
  end

  test "outgoing_queue() returns the outgoing queue" do
    assert_equal ::Configuration.instance.medusa[:outgoing_queue],
                 MedusaIngest.outgoing_queue
  end

end
