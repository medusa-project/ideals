class RedesignInviteesLocalIdentitiesRelationship < ActiveRecord::Migration[7.1]
  def change
    add_column :invitees, :user_id, :bigint
    add_index :invitees, :user_id, unique: true
    add_foreign_key :invitees, :users, on_update: :cascade, on_delete: :cascade

    execute "UPDATE invitees SET user_id = subquery.user_id
             FROM (
               SELECT i.user_id, i.invitee_id
               FROM local_identities i
               LEFT JOIN users u ON i.user_id = u.id
             ) AS subquery
             WHERE invitees.id = subquery.invitee_id;"

    remove_column :local_identities, :invitee_id
  end
end
