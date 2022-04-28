class CreateEmailPatterns < ActiveRecord::Migration[7.0]
  def change
    create_table :email_patterns do |t|
      t.bigint :user_group_id, null: false
      t.string :pattern, null: false

      t.timestamps
    end
    add_foreign_key :email_patterns, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
