class AddFullTextColumnToBitstreams < ActiveRecord::Migration[7.0]
  def change
    add_column :bitstreams, :full_text, :text
    add_column :bitstreams, :full_text_checked_at, :datetime
    add_index :bitstreams, :full_text_checked_at
  end
end
