class RemoveNotNullConstraintFromLocalIdentitiesInviteeIdColumn < ActiveRecord::Migration[7.0]
  def change
    change_column_null :local_identities, :invitee_id, true
  end
end
