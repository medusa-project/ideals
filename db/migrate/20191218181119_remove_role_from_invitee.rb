class RemoveRoleFromInvitee < ActiveRecord::Migration[5.2]
  def change
    remove_column :invitees, :role
  end
end
