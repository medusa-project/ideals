class CascadeForeignKeys < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :administrators, :roles
    add_foreign_key :administrators, :roles, on_update: :cascade, on_delete: :cascade
    remove_foreign_key :administrators, :units
    add_foreign_key :administrators, :units, on_update: :cascade, on_delete: :cascade

    remove_foreign_key :assignments, :roles
    add_foreign_key :assignments, :roles, on_update: :cascade, on_delete: :cascade
    remove_foreign_key :assignments, :users
    add_foreign_key :assignments, :users, on_update: :cascade, on_delete: :cascade

    remove_foreign_key :managers, :collections
    add_foreign_key :managers, :collections, on_update: :cascade, on_delete: :cascade
    remove_foreign_key :managers, :roles
    add_foreign_key :managers, :roles, on_update: :cascade, on_delete: :cascade
  end
end
