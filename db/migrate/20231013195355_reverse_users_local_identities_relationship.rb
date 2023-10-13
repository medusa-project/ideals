class ReverseUsersLocalIdentitiesRelationship < ActiveRecord::Migration[7.1]
  def change
    add_column :local_identities, :user_id, :bigint

    execute "UPDATE local_identities
        SET user_id = subquery.user_id
        FROM (
          SELECT u.id AS user_id, u.local_identity_id AS local_identity_id
          FROM users u
          LEFT JOIN local_identities i ON u.local_identity_id = i.id) AS subquery
        WHERE local_identities.id = subquery.local_identity_id"

    add_foreign_key :local_identities, :users, on_update: :cascade, on_delete: :cascade
    add_index :local_identities, :user_id, unique: true

    remove_foreign_key :users, :local_identities
    remove_column :users, :local_identity_id
  end
end
