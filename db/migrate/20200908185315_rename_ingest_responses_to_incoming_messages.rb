class RenameIngestResponsesToIncomingMessages < ActiveRecord::Migration[6.0]
  def change
    rename_table :ingest_responses, :incoming_messages
    remove_column :incoming_messages, :response_time
  end
end
