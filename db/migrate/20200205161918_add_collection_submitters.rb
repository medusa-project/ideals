class AddCollectionSubmitters < ActiveRecord::Migration[6.0]
  def change
    create_table :submitters, force: :cascade do |t|
      t.bigint :collection_id
      t.bigint :user_id
      t.timestamps
    end
    add_foreign_key :submitters, :users,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :submitters, :collections,
                    on_update: :cascade, on_delete: :cascade
    add_index :submitters, [:collection_id, :user_id], unique: true
  end
end
