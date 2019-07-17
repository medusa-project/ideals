class ChangeInviteeApprovedDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:invitees, :approved, nil)
  end
end
