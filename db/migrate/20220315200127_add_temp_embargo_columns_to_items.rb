class AddTempEmbargoColumnsToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :temp_embargo_type, :string
    add_column :items, :temp_embargo_expires_at, :string
    add_column :items, :temp_embargo_reason, :text
  end
end
