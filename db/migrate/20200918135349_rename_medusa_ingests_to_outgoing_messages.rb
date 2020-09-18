class RenameMedusaIngestsToOutgoingMessages < ActiveRecord::Migration[6.0]
  def change
    rename_table :medusa_ingests, :outgoing_messages
  end
end
