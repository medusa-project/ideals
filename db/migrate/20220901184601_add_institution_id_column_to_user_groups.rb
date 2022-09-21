class AddInstitutionIdColumnToUserGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :user_groups, :institution_id, :bigint
    add_foreign_key :user_groups, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :user_groups, :institution_id

    remove_index :user_groups, :name
    remove_index :user_groups, :key
    add_index :user_groups, [:institution_id, :name], unique: true
    add_index :user_groups, [:institution_id, :key], unique: true
  end
end
