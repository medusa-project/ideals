class AddInstitutionIdColumnToItems < ActiveRecord::Migration[7.0]
  def up
    add_column :items, :institution_id, :bigint
    execute "UPDATE items
        SET institution_id = subquery.institution_id
        FROM (
            SELECT it.id AS item_id, u.institution_id AS institution_id
            FROM items it
            LEFT JOIN collection_item_memberships cim ON it.id = cim.item_id
            LEFT JOIN unit_collection_memberships ucm ON cim.collection_id = ucm.collection_id
            LEFT JOIN units u ON ucm.unit_id = u.id
        ) AS subquery
        WHERE items.id = subquery.item_id;"
    add_foreign_key :items, :institutions, on_update: :cascade, on_delete: :restrict
    add_index :items, :institution_id
  end
  def down
    remove_column :items, :institution_id
  end
end
