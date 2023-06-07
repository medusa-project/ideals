class CreateElementNamespaces < ActiveRecord::Migration[7.0]
  def up
    create_table :element_namespaces do |t|
      t.bigint :institution_id
      t.string :prefix, null: false
      t.string :uri, null: false

      t.timestamps
    end
    add_foreign_key :element_namespaces, :institutions,
                    on_update: :cascade, on_delete: :cascade
    add_index :element_namespaces, [:institution_id, :prefix], unique: true
    add_index :element_namespaces, [:institution_id, :uri], unique: true

    institution_ids = execute("SELECT id FROM institutions;").map{ |r| r['id'] }
    institution_ids.each do |id|
      execute "INSERT INTO element_namespaces(institution_id, prefix, uri, created_at, updated_at) " +
              "VALUES (#{id}, 'dc', 'http://purl.org/dc/elements/1.1/', NOW(), NOW())"
      execute "INSERT INTO element_namespaces(institution_id, prefix, uri, created_at, updated_at) " +
                "VALUES (#{id}, 'ideals', 'https://www.ideals.illinois.edu/ns/', NOW(), NOW())"
    end
  end
  def down
    drop_table :element_namespaces
  end
end
