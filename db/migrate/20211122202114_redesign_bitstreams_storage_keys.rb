class RedesignBitstreamsStorageKeys < ActiveRecord::Migration[6.1]
  def change
    remove_column :bitstreams, :exists_in_staging
    add_column :bitstreams, :permanent_key, :string
  end
end
