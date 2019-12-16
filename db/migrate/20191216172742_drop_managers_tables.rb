class DropManagersTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :managers
    drop_table :collections_managers
  end
end
