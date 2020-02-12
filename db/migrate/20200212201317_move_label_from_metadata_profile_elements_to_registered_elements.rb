class MoveLabelFromMetadataProfileElementsToRegisteredElements < ActiveRecord::Migration[6.0]
  def up
    remove_column :metadata_profile_elements, :label
    add_column :registered_elements, :label, :string
    execute "update registered_elements set label = concat('Label for ', name)"
    change_column :registered_elements, :label, :string, null: false
  end
  def down
    add_column :metadata_profile_elements, :label, :string
    remove_column :registered_elements, :label
  end
end
