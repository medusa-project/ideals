class CreateAffiliations < ActiveRecord::Migration[6.0]
  def change
    create_table :affiliations do |t|
      t.string :name, null: false
      t.timestamps
    end
    create_table :affiliations_user_groups do |t|
      t.bigint :affiliation_id, null: false
      t.bigint :user_group_id, null: false
    end
    add_index :affiliations, :name, unique: true
    add_foreign_key :affiliations_user_groups, :affiliations,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :affiliations_user_groups, :user_groups,
                    on_update: :cascade, on_delete: :cascade

    execute "INSERT INTO affiliations(name, created_at, updated_at) VALUES ('Faculty/Staff', NOW(), NOW())"
    execute "INSERT INTO affiliations(name, created_at, updated_at) VALUES ('Graduate Students', NOW(), NOW())"
    execute "INSERT INTO affiliations(name, created_at, updated_at) VALUES ('Ph.D Students', NOW(), NOW())"
    execute "INSERT INTO affiliations(name, created_at, updated_at) VALUES ('Masters Students', NOW(), NOW())"
    execute "INSERT INTO affiliations(name, created_at, updated_at) VALUES ('Undergraduate Students', NOW(), NOW())"
  end
end
