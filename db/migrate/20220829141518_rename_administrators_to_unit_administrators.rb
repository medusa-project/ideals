class RenameAdministratorsToUnitAdministrators < ActiveRecord::Migration[7.0]
  def change
    rename_table :administrators, :unit_administrators
  end
end
