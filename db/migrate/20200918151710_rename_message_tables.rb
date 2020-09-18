class RenameMessageTables < ActiveRecord::Migration[6.0]
  def up
    drop_table :incoming_messages

    rename_table :outgoing_messages, :messages
    add_column :messages, :raw_request, :text
    add_column :messages, :raw_response, :text
    remove_foreign_key :messages, :bitstreams, column: :bitstream_id
    add_foreign_key :messages, :bitstreams,
                    column: :bitstream_id,
                    on_update: :cascade,
                    on_delete: :nullify
    remove_index :messages, :medusa_uuid
    remove_index :messages, :staging_key
    remove_index :messages, :target_key
    change_column_null :messages, :staging_key, true
    change_column_null :messages, :target_key, true
  end
  def down
    create_table :incoming_messages do |t|
    end
    remove_column :messages, :raw_request
    remove_column :messages, :raw_response
    remove_foreign_key :messages, :bitstreams, column: :bitstream_id
    add_foreign_key :messages, :bitstreams,
                    column: :bitstream_id,
                    on_update: :cascade,
                    on_delete: :nullify
    change_column_null :messages, :staging_key, false
    change_column_null :messages, :target_key, false
    add_index :messages, :medusa_uuid
    add_index :messages, :staging_key
    add_index :messages, :target_key
    rename_table :messages, :outgoing_messages
  end
end
