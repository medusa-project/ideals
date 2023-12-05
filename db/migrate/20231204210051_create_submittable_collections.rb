class CreateSubmittableCollections < ActiveRecord::Migration[7.1]
  def change
    create_table :submittable_collections do |t|
      t.bigint :user_id
      t.bigint :collection_id
      t.timestamps
    end
    add_foreign_key :submittable_collections, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :submittable_collections, :collections, on_update: :cascade, on_delete: :cascade
    add_index :submittable_collections, [:user_id, :collection_id], unique: true
    add_index :submittable_collections, :user_id
    add_column :users, :submittable_collections_cached_at, :datetime
    add_column :users, :caching_submittable_collections_task_id, :bigint
    add_foreign_key :users, :tasks, column: :caching_submittable_collections_task_id, on_update: :cascade, on_delete: :nullify
  end
end
