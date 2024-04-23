class AddInstitutionScopedIndexesOnEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :events, [:institution_id, :event_type]
    add_index :events, [:institution_id, :happened_at]
  end
end
