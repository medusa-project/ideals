class AddForeignKeyBetweenIdentitiesAndInvitees < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :identities, :invitees, on_update: :cascade, on_delete: :cascade
  end
end
