class AddItemsTempEmbargoKindColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :temp_embargo_kind, :integer
  end
end
