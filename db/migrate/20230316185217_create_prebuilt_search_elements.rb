class CreatePrebuiltSearchElements < ActiveRecord::Migration[7.0]
  def change
    create_table :prebuilt_search_elements do |t|
      t.bigint :prebuilt_search_id, null: false
      t.bigint :registered_element_id, null: false
      t.string :term, null: false

      t.timestamps
    end
    add_foreign_key :prebuilt_search_elements, :prebuilt_searches, on_update: :cascade, on_delete: :cascade
    add_foreign_key :prebuilt_search_elements, :registered_elements, on_update: :cascade, on_delete: :restrict
    add_index :prebuilt_search_elements, :prebuilt_search_id
    add_index :prebuilt_search_elements, :registered_element_id
  end
end
