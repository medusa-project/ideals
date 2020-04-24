class AddNotNullConstraintOnInviteesApprovalState < ActiveRecord::Migration[6.0]
  def change
    change_column_null :invitees, :approval_state, false
  end
end
