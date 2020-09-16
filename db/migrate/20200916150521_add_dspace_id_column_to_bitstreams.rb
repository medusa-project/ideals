class AddDspaceIdColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :dspace_id, :string
  end
end
