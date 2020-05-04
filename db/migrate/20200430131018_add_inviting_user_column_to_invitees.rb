class AddInvitingUserColumnToInvitees < ActiveRecord::Migration[6.0]
  def change
    add_column :invitees, :inviting_user_id, :bigint
    add_foreign_key :invitees, :users, column: :inviting_user_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
