class MoveInviteesInvitingUserIdColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :invitees, :inviting_user_id_new, :bigint
    execute "UPDATE invitees SET inviting_user_id_new = inviting_user_id;"
    remove_column :invitees, :inviting_user_id
    rename_column :invitees, :inviting_user_id_new, :inviting_user_id
    add_index :invitees, :inviting_user_id
    add_foreign_key :invitees, :users, column: :inviting_user_id,
                    on_update: :cascade, on_delete: :cascade
  end
end
