class AddRejectionReasonColumnToInvitees < ActiveRecord::Migration[7.0]
  def change
    add_column :invitees, :rejection_reason, :text
  end
end
