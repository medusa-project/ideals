class DropAssignmentsAndRoles < ActiveRecord::Migration[6.0]
  def change
    drop_table :assignments
    drop_table :roles
  end
end
