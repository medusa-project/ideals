class AddIndexesOnEmbargoes < ActiveRecord::Migration[7.0]
  def change
    add_index :embargoes, :kind
    add_index :embargoes, :perpetual
  end
end
