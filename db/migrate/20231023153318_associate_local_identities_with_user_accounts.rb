class AssociateLocalIdentitiesWithUserAccounts < ActiveRecord::Migration[7.1]
  def change
    execute("UPDATE local_identities i SET user_id = subquery.user_id
            FROM (
                SELECT i.user_id
                FROM local_identities i
                LEFT JOIN users u ON i.email = u.email
                WHERE i.user_id IS NULL) AS subquery
            WHERE i.user_id IS NULL;")
  end
end
