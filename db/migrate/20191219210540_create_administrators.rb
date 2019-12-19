class CreateAdministrators < ActiveRecord::Migration[5.2]
  def change
    create_table :administrators do |t|
      t.references :role, foreign_key: true
      t.references :unit, foreign_key: true

      t.timestamps
    end
  end
end
