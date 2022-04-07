class AddPositionColumnToAscribedElements < ActiveRecord::Migration[7.0]
  def change
    add_column :ascribed_elements, :position, :integer, default: 1, null: false
  end
end
