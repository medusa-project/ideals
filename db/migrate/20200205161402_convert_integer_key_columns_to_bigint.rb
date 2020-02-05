class ConvertIntegerKeyColumnsToBigint < ActiveRecord::Migration[6.0]
  def change
    change_column :bitstreams, :item_id, :bigint
    change_column :collection_unit_relationships, :collection_id, :bigint
    change_column :collection_unit_relationships, :unit_id, :bigint
    change_column :identities, :invitee_id, :bigint
    change_column :item_collection_relationships, :collection_id, :bigint
    change_column :item_collection_relationships, :item_id, :bigint
    change_column :units, :parent_id, :bigint
    remove_column :collections, :manager_id
  end
end
