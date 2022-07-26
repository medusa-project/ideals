class CreateDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :downloads do |t|
      t.string :key, null: false
      t.string :filename
      t.string :url
      t.bigint :task_id
      t.boolean :expired, null: false, default: false
      t.string :ip_address

      t.timestamps
    end
    add_foreign_key :downloads, :tasks, on_update: :cascade, on_delete: :nullify
    add_index :downloads, :key, unique: true
    add_index :downloads, :task_id
  end
end
