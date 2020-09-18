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
          operation: Message::Operation::DELETE,
          uuid:      node.uuid
      }
      AmqpHelper::Connector[:ideals].send_message(Message.outgoing_queue,
                                                  message)
    end
  end

  namespace :messages do

    desc "Fetch Medusa RabbitMQ messages"
    task :fetch => :environment do
      while true
        AmqpHelper::Connector[:ideals].with_message(Message.incoming_queue) do |payload|
          exit if payload.nil?
          MessageHandler.handle(payload)
        end
      end
    end

    desc "List the last 1000 messages"
    task :log => :environment do
      Message.order(:updated_at).limit(1000).each do |message|
        puts "-------\n"\
        "#{message.id.to_s.ljust(7, ' ')} CREATED:     #{message.created_at.localtime}\n"\
        "        UPDATED:     #{message.updated_at.localtime}\n"\
        "        OPERATION:   #{message.operation}\n"\
        "        ITEM:        #{message.bitstream.item_id}\n"\
        "        BITSTREAM:   #{message.bitstream_id}\n"\
        "        STAGING KEY: #{message.staging_key}\n"\
        "        TARGET KEY : #{message.target_key}\n"\
        "        STATUS:      #{message.status}\n"\
        "        RSPONS TIME: #{message.response_time}\n"\
        "        MEDUSA UUID: #{message.medusa_uuid}\n"\
        "        ERROR:       #{message.error_text}\n\n"
      end
    end

    desc "Resend failed Medusa messages"
    task :retry_failed => :environment do
      Message.where(status: Message::Status::ERROR).each(&:resend)
    end

  end

end
