namespace :medusa do

  desc "Delete a file"
  task :delete, [:uuid] => :environment do |task, args|
    message = Message.create!(operation:   Message::Operation::DELETE,
                              medusa_uuid: args[:uuid])
    message.send_message
  end

  desc "Delete all bitstreams"
  task :delete_all_bitstreams => :environment do
    raise "This task is not available in production." if Rails.env.production?
    config = ::Configuration.instance
    fg_id  = config.medusa[:file_group_id]
    fg     = ::Medusa::FileGroup.with_id(fg_id)
    dir    = fg.directory
    dir.walk_tree do |node|
      next unless node.kind_of?(::Medusa::File)
      message = Message.create!(operation:   Message::Operation::DELETE,
                                medusa_uuid: node.uuid,
                                target_key:  node.relative_key)
      message.send_message
    end
  end

  namespace :messages do

    desc "Fetch Medusa RabbitMQ messages"
    task :fetch => :environment do
      loop  = true
      count = 0
      while loop
        AmqpHelper::Connector[:ideals].with_message(Message.incoming_queue) do |payload|
          loop = payload.present?
          if loop
            count += 1
            MessageHandler.handle(payload)
          end
        end
      end
      puts "Fetched #{count} messages."
    end

    desc "List the last 1000 messages"
    task :log => :environment do
      Message.order(:updated_at).limit(1000).each do |message|
        lines = []
        lines << "#{message.id}----------------------------------"
        lines << "CREATED:       #{message.created_at.localtime}"
        lines << "UPDATED:       #{message.updated_at.localtime}"
        lines << "OPERATION:     #{message.operation}"
        lines << "ITEM:          #{message.bitstream.item_id}"
        lines << "BITSTREAM:     #{message.bitstream_id}"
        lines << "STAGING KEY:   #{message.staging_key}"
        lines << "TARGET KEY :   #{message.target_key}"
        lines << "STATUS:        #{message.status}"
        lines << "RESPONSE TIME: #{message.response_time}"
        lines << "MEDUSA UUID:   #{message.medusa_uuid}"
        lines << "ERROR:         #{message.error_text}" if message.error_text
        puts lines.join("\n") + "\n\n"
      end
    end

    desc "Resend failed Medusa messages"
    task :retry_failed => :environment do
      Message.where(status: Message::Status::ERROR).each(&:resend)
    end

  end

end
