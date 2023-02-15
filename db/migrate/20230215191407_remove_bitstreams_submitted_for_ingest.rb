class RemoveBitstreamsSubmittedForIngest < ActiveRecord::Migration[7.0]
  def change
    remove_column :bitstreams, :submitted_for_ingest
  end
end
