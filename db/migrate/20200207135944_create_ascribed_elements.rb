class CreateAscribedElements < ActiveRecord::Migration[6.0]
  def change
    create_table :ascribed_elements do |t|
      t.text :string, null: false
      t.bigint :registered_element_id, null: false
      t.bigint :collection_id
      t.bigint :item_id

      t.timestamps
    end
    add_foreign_key :ascribed_elements, :registered_elements,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :ascribed_elements, :collections,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :ascribed_elements, :items,
                    on_update: :cascade, on_delete: :cascade
  end
end
