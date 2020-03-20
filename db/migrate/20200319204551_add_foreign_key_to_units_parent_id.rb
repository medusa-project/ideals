class AddForeignKeyToUnitsParentId < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :units, :units, column: :parent_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
