class AddParentIdColumnToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :parent_id, :bigint
    add_foreign_key :collections, :collections, column: :parent_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
