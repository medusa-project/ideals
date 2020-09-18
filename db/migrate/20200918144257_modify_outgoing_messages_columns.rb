class ModifyOutgoingMessagesColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :outgoing_messages, :operation, :string
    execute "update outgoing_messages set operation = 'ingest'"
    change_column_null :outgoing_messages, :operation, false
    rename_column :outgoing_messages, :request_status, :status
    rename_column :outgoing_messages, :medusa_path, :medusa_key
  end
end
