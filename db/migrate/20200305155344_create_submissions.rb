class CreateSubmissions < ActiveRecord::Migration[6.0]
  def change
    create_table :submissions do |t|
      t.bigint :user_id
      t.bigint :collection_id

      t.timestamps
    end

    add_foreign_key :submissions, :collections,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :submissions, :users,
                    on_update: :cascade, on_delete: :cascade
  end
end
