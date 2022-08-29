class RenameAdministratorGroupsToUnitAdministratorGroups < ActiveRecord::Migration[7.0]
  def change
    rename_table :administrator_groups, :unit_administrator_groups
  end
end
