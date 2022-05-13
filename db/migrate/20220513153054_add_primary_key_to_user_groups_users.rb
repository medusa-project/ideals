class AddPrimaryKeyToUserGroupsUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :user_groups_users, :id, :primary_key
  end
end
