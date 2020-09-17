class AddSubmittedForIngestColumnToBitstreams < ActiveRecord::Migration[6.0]
  def change
    add_column :bitstreams, :submitted_for_ingest, :boolean, default: false, null: false
  end
end
