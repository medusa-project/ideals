class AddAllElementsRelevanceWeightColumnToMetadataProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_profiles, :all_elements_relevance_weight, :integer, default: 5, null: false
  end
end
