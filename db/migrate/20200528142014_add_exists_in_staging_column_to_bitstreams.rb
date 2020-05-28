class AddExistsInStagingColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :exists_in_staging, :boolean, default: false, null: false
  end
end
