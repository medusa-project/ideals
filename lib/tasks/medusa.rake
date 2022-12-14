namespace :medusa do

  desc "Delete a file"
  task :delete, [:uuid] => :environment do |task, args|
    message = Message.create!(operation:   Message::Operation::DELETE,
                              medusa_uuid: args[:uuid])
    message.send_message
  end

  desc "Delete all files in the file group"
  task :delete_all_files => :environment do
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
      count = 0
      Institution.where.not(incoming_message_queue: nil).each do |institution|
        loop        = true
        while loop
          AmqpHelper::Connector[:ideals].with_message(institution.incoming_message_queue) do |payload|
            loop = payload.present?
            if loop
              count += 1
              MessageHandler.handle(payload)
            end
          end
        end
      end
      puts "Fetched #{count} messages."
    end

    desc "List the last 1000 messages"
    task :log => :environment do
      Message.order(:updated_at).limit(1000).each do |message|
        puts message.as_console + "\n\n"
      end
    end

    desc "Resend failed Medusa messages"
    task :retry_failed => :environment do
      Message.where(status: Message::Status::ERROR).each(&:resend)
    end

  end

end
