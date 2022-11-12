class AddQueueColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :outgoing_message_queue, :string
    add_column :institutions, :incoming_message_queue, :string
    add_index :institutions, :outgoing_message_queue, unique: true
    add_index :institutions, :incoming_message_queue, unique: true

    execute "UPDATE institutions SET outgoing_message_queue = 'ideals_to_medusa' WHERE key = 'uiuc';"
    execute "UPDATE institutions SET incoming_message_queue = 'medusa_to_ideals' WHERE key = 'uiuc';"
  end
end
