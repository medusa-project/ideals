class AddNameColumnToAdGroups < ActiveRecord::Migration[7.0]
  def change
    drop_table :ad_groups_user_groups
    drop_table :ad_groups_users
    execute "DELETE FROM ad_groups;"
    add_column :ad_groups, :user_group_id, :bigint, null: false
    add_column :ad_groups, :name, :string, null: false
    remove_column :ad_groups, :urn
    add_foreign_key :ad_groups, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
