class AddIndexesOnFkColumns2 < ActiveRecord::Migration[7.0]
  def change
    add_index :ad_groups, :user_group_id
    add_index :email_patterns, :user_group_id
    add_index :metadata_profile_elements, :indexed
    add_index :tasks, :user_id
  end
end
