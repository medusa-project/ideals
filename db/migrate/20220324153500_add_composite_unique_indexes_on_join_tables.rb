class AddCompositeUniqueIndexesOnJoinTables < ActiveRecord::Migration[7.0]
  def change
    add_index :ad_groups_user_groups, [:ad_group_id, :user_group_id], unique: true
    remove_index :ad_groups_user_groups, :ad_group_id
    remove_index :ad_groups_user_groups, :user_group_id

    add_index :ad_groups_users, [:ad_group_id, :user_id], unique: true

    add_index :administrator_groups, [:user_group_id, :unit_id], unique: true
    remove_index :administrator_groups, :user_group_id
    remove_index :administrator_groups, :unit_id

    remove_index :administrators, :unit_id
    remove_index :administrators, :user_id

    add_index :affiliations_user_groups, [:affiliation_id, :user_group_id], unique: true, name: "aff_ug"
    remove_index :affiliations_user_groups, :affiliation_id
    remove_index :affiliations_user_groups, :user_group_id

    add_index :bitstream_authorizations, [:item_id, :user_group_id], unique: true
    remove_index :bitstream_authorizations, :item_id
    remove_index :bitstream_authorizations, :user_group_id

    add_index :bitstreams, :bundle
    add_index :bitstreams, :medusa_uuid
    add_index :bitstreams, :original_filename
    add_index :bitstreams, :permanent_key

    remove_index :collection_item_memberships, :collection_id
    remove_index :collection_item_memberships, :item_id

    add_index :collections, :buried

    add_index :departments, [:user_group_id, :user_id], unique: true
    remove_index :departments, :user_group_id
    remove_index :departments, :user_id

    add_index :manager_groups, [:collection_id, :user_group_id], unique: true
    remove_index :manager_groups, :collection_id
    remove_index :manager_groups, :user_group_id

    remove_index :managers, :user_id
    remove_index :managers, :collection_id

    add_index :submitter_groups, [:collection_id, :user_group_id], unique: true
    remove_index :submitter_groups, :collection_id
    remove_index :submitter_groups, :user_group_id

    remove_index :submitters, :collection_id
    remove_index :submitters, :user_id

    remove_index :unit_collection_memberships, :collection_id
    remove_index :unit_collection_memberships, :unit_id

    add_index :user_groups_users, [:user_id, :user_group_id], unique: true
    remove_index :user_groups_users, :user_group_id
    remove_index :user_groups_users, :user_id
  end
end
