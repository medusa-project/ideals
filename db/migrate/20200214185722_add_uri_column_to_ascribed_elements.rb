class AddUriColumnToAscribedElements < ActiveRecord::Migration[6.0]
  def change
    add_column :ascribed_elements, :uri, :string
  end
end
