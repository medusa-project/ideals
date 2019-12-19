class CreateManagers < ActiveRecord::Migration[5.2]
  def change
    create_table :managers do |t|
      t.references :role, foreign_key: true
      t.references :collection, foreign_key: true

      t.timestamps
    end
  end
end
