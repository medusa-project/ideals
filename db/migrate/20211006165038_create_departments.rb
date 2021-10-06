class CreateDepartments < ActiveRecord::Migration[6.0]
  def change
    create_table :departments do |t|
      t.string :name, null: false
      t.bigint :user_group_id, null: false
      t.timestamps
    end
    add_foreign_key :departments, :user_groups,
                    on_update: :cascade, on_delete: :cascade
  end
end
