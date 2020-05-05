class AddLocalIdentityIdColumnToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :local_identity_id, :bigint
    add_foreign_key :users, :local_identities,
                    on_update: :cascade, on_delete: :cascade
  end
end
