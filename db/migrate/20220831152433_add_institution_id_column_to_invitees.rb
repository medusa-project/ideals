class AddInstitutionIdColumnToInvitees < ActiveRecord::Migration[7.0]
  def change
    add_column :invitees, :institution_id, :bigint
    add_index :invitees, :institution_id
    add_foreign_key :invitees, :institutions, on_update: :cascade, on_delete: :restrict
  end
end
