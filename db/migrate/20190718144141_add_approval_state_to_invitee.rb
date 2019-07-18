class AddApprovalStateToInvitee < ActiveRecord::Migration[5.2]
  def change
    add_column :invitees, :approval_state, :string
  end
end
