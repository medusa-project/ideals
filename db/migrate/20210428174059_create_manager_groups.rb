class CreateManagerGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :manager_groups do |t|
      t.bigint :collection_id, null: false
      t.bigint :user_group_id, null: false

      t.timestamps
    end
    add_foreign_key :manager_groups, :collections,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :manager_groups, :user_groups,
                    on_update: :cascade, on_delete: :cascade
  end
end
