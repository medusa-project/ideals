class AddAffiliationIdColumnToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :affiliation_id, :bigint, null: true
    add_foreign_key :users, :affiliations, on_update: :cascade, on_delete: :nullify
  end
end
