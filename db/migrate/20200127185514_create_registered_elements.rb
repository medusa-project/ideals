class CreateRegisteredElements < ActiveRecord::Migration[6.0]
  def change
    create_table :registered_elements do |t|
      t.string :name, null: false
      t.text :scope_note

      t.timestamps
    end
    add_index :registered_elements, :name, unique: true
  end
end
