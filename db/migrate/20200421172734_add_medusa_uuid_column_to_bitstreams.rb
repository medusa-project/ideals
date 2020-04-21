class AddMedusaUuidColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :medusa_uuid, :string
  end
end
