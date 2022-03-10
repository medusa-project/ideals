class AddEmbargoesUserGroups < ActiveRecord::Migration[7.0]
  def change
    create_join_table :embargoes, :user_groups
    add_foreign_key :embargoes_user_groups, :embargoes, on_update: :cascade, on_delete: :cascade
    add_foreign_key :embargoes_user_groups, :user_groups, on_update: :cascade, on_delete: :cascade
    add_index :embargoes_user_groups, [:embargo_id, :user_group_id], unique: true
  end
end
