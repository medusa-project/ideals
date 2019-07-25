class CreateManagers < ActiveRecord::Migration[5.2]
  def change
    create_table :managers do |t|
      t.string :uid
      t.string :provider

      t.timestamps
    end
  end
end
