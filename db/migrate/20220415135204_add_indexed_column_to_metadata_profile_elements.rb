class AddIndexedColumnToMetadataProfileElements < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_profile_elements, :indexed, :boolean, default: true, null: false
  end
end
