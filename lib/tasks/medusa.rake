namespace :medusa do

  desc "Delete all bitstreams"
  task :delete_all_bitstreams => :environment do
    raise "This task is not available in production." if Rails.env.production?
    config = ::Configuration.instance
    fg_id  = config.medusa[:file_group_id]
    fg     = ::Medusa::FileGroup.with_id(fg_id)
    dir    = fg.directory
    dir.walk_tree do |node|
      next unless node.kind_of?(::Medusa::File)
      message = {
          operation: "delete",
          uuid:      node.uuid
      }
      AmqpHelper::Connector[:ideals].send_message(MedusaIngest.outgoing_queue,
                                                  message)
    end
  end

  desc "Fetch Medusa RabbitMQ messages"
  task :fetch_messages => :environment do
    while true
      AmqpHelper::Connector[:ideals].with_message(MedusaIngest.incoming_queue) do |payload|
        exit if payload.nil?
        MedusaIngest.on_medusa_message(payload)
      end
    end
  end

  desc "Resend failed Medusa messages"
  task :retry_failed => :environment do
    failed_ingests = MedusaIngest.where(request_status: "error")
    failed_ingests.each do |ingest|
      ingest.update!(request_status: "resent",
                     error_text: nil,
                     response_time: nil)
      ingest.send_medusa_ingest_message
    end
  end

end
