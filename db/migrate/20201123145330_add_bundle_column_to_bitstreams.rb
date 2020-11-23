class AddBundleColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :bundle, :integer, null: false, default: 0
  end
end
