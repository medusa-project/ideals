class CreateJoinTableManagersCollections < ActiveRecord::Migration[5.2]
  def change
    create_join_table :managers, :collections do |t|
      # t.index [:manager_id, :collection_id]
      # t.index [:collection_id, :manager_id]
    end
  end
end
