namespace :medusa do

  desc "Delete a file"
  task :delete, [:uuid] => :environment do |task, args|
    Bitstream.find_by_medusa_uuid(args[:uuid]).delete_from_medusa
  end

  namespace :messages do

    desc "Fetch Medusa RabbitMQ messages"
    task :fetch => :environment do
      count = 0
      Institution.where.not(incoming_message_queue: nil).each do |institution|
        loop        = true
        while loop
          AmqpHelper::Connector[:ideals].with_message(institution.incoming_message_queue) do |payload|
            loop = payload.present?
            if loop
              count += 1
              begin
                MessageHandler.handle(payload)
              rescue => e
                puts "#{e}"
                IdealsMailer.error(e.message).deliver_now
              end
            end
          end
        end
      end
      puts "Fetched #{count} messages."
    end

    desc "Delete ingest messages whose associated bitstreams have vanished"
    task :delete_stale => :environment do
      Message.
        where(operation: Message::Operation::INGEST).
        where(bitstream_id: nil).
        destroy_all
    end

    desc "List the last 1000 messages"
    task :log => :environment do
      Message.order(:updated_at).limit(1000).each do |message|
        puts message.as_console + "\n\n"
      end
    end

    desc "Resend failed Medusa messages"
    task :retry_failed => :environment do
      Message.where("status = ? AND ((operation = ? AND bitstream_id IS NOT NULL) OR (operation = ?))",
                    Message::Status::ERROR, Message::Operation::INGEST, Message::Operation::DELETE).
        each(&:resend)
    end

    desc "Resend Medusa messages with no response"
    task :retry_no_response => :environment do
      Message.where(status: nil).each(&:resend)
    end

  end

end
