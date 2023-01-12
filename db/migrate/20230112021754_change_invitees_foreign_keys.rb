class ChangeInviteesForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :invitees, :institutions
    remove_foreign_key :invitees, :users, column: :inviting_user_id
    add_foreign_key :invitees, :institutions, on_update: :cascade, on_delete: :cascade
    add_foreign_key :invitees, :users, column: :inviting_user_id, on_update: :cascade, on_delete: :cascade
  end
end
