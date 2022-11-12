class AddInstitutionIdColumnToCollections < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :institution_id, :bigint
    execute "UPDATE collections
        SET institution_id = subquery.institution_id
        FROM (
            SELECT c.id AS collection_id, u.institution_id AS institution_id
            FROM collections c
            LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = c.id
            LEFT JOIN units u ON ucm.unit_id = u.id
        ) AS subquery
        WHERE collections.id = subquery.collection_id;"
    change_column_null :collections, :institution_id, false
    add_foreign_key :collections, :institutions, on_update: :cascade, on_delete: :restrict
    add_index :collections, :institution_id
  end
end
