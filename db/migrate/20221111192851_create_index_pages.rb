class CreateIndexPages < ActiveRecord::Migration[7.0]
  def change
    create_table :index_pages do |t|
      t.string :name, null: false
      t.bigint :institution_id, null: false

      t.timestamps
    end
    create_join_table :index_pages, :registered_elements
    add_index :index_pages, :institution_id
    add_index :index_pages, [:name, :institution_id], unique: true
    add_index :index_pages_registered_elements, [:index_page_id, :registered_element_id],
              unique: true, name: "index_index_pages_r_es_on_index_page_id_and_r_e_id"
  end
end
