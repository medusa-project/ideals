class CreateHosts < ActiveRecord::Migration[6.0]
  def change
    create_table :hosts do |t|
      t.string :pattern, null: false
      t.bigint :user_group_id

      t.timestamps
    end
    add_foreign_key :hosts, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
