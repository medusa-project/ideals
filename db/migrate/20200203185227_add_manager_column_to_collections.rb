class AddManagerColumnToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :manager_id, :integer
    add_foreign_key :collections, :users, column: :manager_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
