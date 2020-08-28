class RemovePrefixColumnFromHandles < ActiveRecord::Migration[6.0]
  def change
    remove_column :handles, :prefix
  end
end
