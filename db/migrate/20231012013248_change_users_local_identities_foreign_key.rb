class ChangeUsersLocalIdentitiesForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :users, :local_identities
    add_foreign_key :users, :local_identities,
                    on_update: :cascade, on_delete: :nullify
  end
end
