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

    desc "Resend failed Medusa messages"
    task :retry_failed => :environment do
      Message.where(status: "error").each(&:resend)
    end

  end

end
