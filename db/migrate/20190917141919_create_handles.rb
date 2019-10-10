class CreateHandles < ActiveRecord::Migration[5.2]
  def change
    create_table :handles do |t|
      t.string :handle
      t.integer :resource_type_id
      t.integer :resource_id

      t.timestamps
    end
  end
end
