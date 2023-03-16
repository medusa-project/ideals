class CreatePrebuiltSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :prebuilt_searches do |t|
      t.string :name, null: false
      t.bigint :institution_id, null: false
      t.bigint :ordering_element_id
      t.integer :direction, null: false, default: 0
      t.timestamps
    end
    add_index :prebuilt_searches, :institution_id
    add_index :prebuilt_searches, :ordering_element_id
    add_foreign_key :prebuilt_searches, :institutions,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :prebuilt_searches, :registered_elements,
                    column: :ordering_element_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
