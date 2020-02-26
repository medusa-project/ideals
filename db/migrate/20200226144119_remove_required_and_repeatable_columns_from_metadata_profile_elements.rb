class RemoveRequiredAndRepeatableColumnsFromMetadataProfileElements < ActiveRecord::Migration[6.0]
  def change
    remove_column :metadata_profile_elements, :required
    remove_column :metadata_profile_elements, :repeatable
  end
end
