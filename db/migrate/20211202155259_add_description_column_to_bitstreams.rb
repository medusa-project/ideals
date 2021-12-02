class AddDescriptionColumnToBitstreams < ActiveRecord::Migration[6.1]
  def change
    add_column :bitstreams, :description, :text
  end
end
