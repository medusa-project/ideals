class RemoveOrgDnColumnFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :org_dn
  end
end
