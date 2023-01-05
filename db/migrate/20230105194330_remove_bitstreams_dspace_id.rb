class RemoveBitstreamsDspaceId < ActiveRecord::Migration[7.0]
  def change
    remove_column :bitstreams, :dspace_id
  end
end
