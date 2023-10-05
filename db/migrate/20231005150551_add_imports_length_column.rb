class AddImportsLengthColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :imports, :length, :bigint
  end
end
