namespace :medusa do
  desc "Fetch Medusa RabbitMQ messages"
  task :fetch_messages => :environment do
    while true
      AmqpHelper::Connector[:ideals].with_message(MedusaIngest.incoming_queue) do |payload|
        exit if payload.nil?
        MedusaIngest.on_medusa_message(payload)
      end
      sleep 0.1
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
