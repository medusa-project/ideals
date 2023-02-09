class ChangeItemsUsersForeignKeyCascade < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "items", "users", column: "submitter_id"
    add_foreign_key "items", "users", column: "submitter_id", on_update: :cascade, on_delete: :nullify
  end
end
