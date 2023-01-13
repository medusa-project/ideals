class AddInstitutionAdminColumnToInvitees < ActiveRecord::Migration[7.0]
  def change
    add_column :invitees, :institution_admin, :boolean, default: false, null: false
  end
end
