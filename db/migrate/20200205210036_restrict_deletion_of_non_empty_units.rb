class RestrictDeletionOfNonEmptyUnits < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :collection_unit_relationships, :units
    add_foreign_key :collection_unit_relationships, :units,
                    on_update: :cascade, on_delete: :restrict
  end
end
