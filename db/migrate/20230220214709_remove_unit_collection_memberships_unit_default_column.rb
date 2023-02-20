class RemoveUnitCollectionMembershipsUnitDefaultColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :unit_collection_memberships, :unit_default
  end
end
