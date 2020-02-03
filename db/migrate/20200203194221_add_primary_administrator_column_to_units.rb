class AddPrimaryAdministratorColumnToUnits < ActiveRecord::Migration[6.0]
  def change
    add_column :units, :primary_administrator_id, :integer
    add_foreign_key :units, :users, column: :primary_administrator_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
