class RemoveApprovedFromInvitee < ActiveRecord::Migration[5.2]
  def change
    remove_column :invitees, :approved, :boolean
  end
end
