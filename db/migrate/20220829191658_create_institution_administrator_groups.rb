class CreateInstitutionAdministratorGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :institution_administrator_groups do |t|
      t.bigint :institution_id
      t.bigint :user_group_id

      t.timestamps
    end
    add_index :institution_administrator_groups, [:institution_id, :user_group_id], unique: true,
              name: "index_ins_admin_groups_on_ins_id_and_user_group_id"
    add_index :institution_administrator_groups, :institution_id
    add_index :institution_administrator_groups, :user_group_id
  end
end
