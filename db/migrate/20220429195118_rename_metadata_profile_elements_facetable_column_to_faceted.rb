class RenameMetadataProfileElementsFacetableColumnToFaceted < ActiveRecord::Migration[7.0]
  def change
    rename_column :metadata_profile_elements, :facetable, :faceted
  end
end
