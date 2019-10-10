class CreateCollectionGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_groups do |t|
      t.string :title
      t.integer :group_id
      t.integer :parent_group_id
      t.string :group_type

      t.timestamps
    end
  end
end
