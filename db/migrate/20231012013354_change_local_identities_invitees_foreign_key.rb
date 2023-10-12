class ChangeLocalIdentitiesInviteesForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :local_identities, :invitees
    add_foreign_key :local_identities, :invitees,
                    on_update: :cascade, on_delete: :nullify
  end
end
