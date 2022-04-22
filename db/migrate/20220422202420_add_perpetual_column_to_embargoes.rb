class AddPerpetualColumnToEmbargoes < ActiveRecord::Migration[7.0]
  def change
    add_column :embargoes, :perpetual, :boolean, default: false, null: false
  end
end
