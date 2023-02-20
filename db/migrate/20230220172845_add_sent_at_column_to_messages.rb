class AddSentAtColumnToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :sent_at, :datetime
    execute "UPDATE messages SET sent_at = created_at;"
  end
end
