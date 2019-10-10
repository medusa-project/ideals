class AddPartsToHandle < ActiveRecord::Migration[5.2]
  def change
    add_column :handles, :prefix, :integer
    add_column :handles, :suffix, :integer
  end
end
