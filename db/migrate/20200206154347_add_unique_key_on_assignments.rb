class AddUniqueKeyOnAssignments < ActiveRecord::Migration[6.0]
  def change
    add_index :assignments, [:user_id, :role_id], unique: true
  end
end
