class CreateInstitutions < ActiveRecord::Migration[6.0]
  UIUC_DN = "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu"

  def up
    create_table :institutions do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :org_dn, null: false
      t.timestamps
    end
    add_index :institutions, :key, unique: true
    add_index :institutions, :name, unique: true

    execute "INSERT INTO institutions(key, name, org_dn, created_at, updated_at) "\
        "VALUES ('uiuc', 'University of Illinois at Urbana-Champaign Library', '#{UIUC_DN}', NOW(), NOW());"
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']

    add_column :units, :institution_id, :bigint
    add_column :users, :org_dn, :string

    execute "UPDATE units SET institution_id = #{id};"

    execute "UPDATE users SET org_dn = '#{UIUC_DN}' "\
        "WHERE email LIKE '%illinois.edu' OR email LIKE '%.uiuc.edu';"

    add_foreign_key :units, :institutions, on_update: :cascade, on_delete: :restrict
  end

  def down
    remove_column :units, :institution_id
    remove_column :users, :org_dn
    drop_table :institutions
  end
end
