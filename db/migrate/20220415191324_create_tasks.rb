class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.bigint :user_id
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.string :status_text, null: false
      t.float :percent_complete, default: 0, null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean :indeterminate, default: false, null: false
      t.text :detail
      t.text :backtrace

      t.timestamps
    end
    add_foreign_key :tasks, :users, on_update: :cascade, on_delete: :nullify
    add_index :tasks, :status
    add_index :tasks, :started_at
    add_index :tasks, :stopped_at
  end
end
