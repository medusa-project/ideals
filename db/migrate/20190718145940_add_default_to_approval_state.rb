class AddDefaultToApprovalState < ActiveRecord::Migration[5.2]
  def change
    change_column :invitees, :approval_state, :string, default: 'pending'
  end
end
