class CreateInstitutionAdministrators < ActiveRecord::Migration[7.0]
  def change
    create_table :institution_administrators do |t|
      t.bigint :user_id
      t.bigint :institution_id

      t.timestamps
    end
    add_foreign_key :institution_administrators, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :institution_administrators, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :institution_administrators, :user_id
    add_index :institution_administrators, :institution_id
    add_index :institution_administrators, [:user_id, :institution_id], unique: true
  end
end
