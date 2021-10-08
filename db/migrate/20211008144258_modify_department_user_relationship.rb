class ModifyDepartmentUserRelationship < ActiveRecord::Migration[6.0]
  def change
    change_column_null :departments, :user_group_id, true

    add_column :departments, :user_id, :bigint
    add_foreign_key :departments, :users, on_update: :cascade, on_delete: :cascade
  end
end
