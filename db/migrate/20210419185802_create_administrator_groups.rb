class CreateAdministratorGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :administrator_groups do |t|
      t.bigint :unit_id, null: false
      t.bigint :user_group_id, null: false

      t.timestamps
    end
    add_foreign_key :administrator_groups, :units, on_update: :cascade, on_delete: :cascade
    add_foreign_key :administrator_groups, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
