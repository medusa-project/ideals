class DropSubmissions < ActiveRecord::Migration[6.0]
  def change
    drop_table :submissions
  end
end
