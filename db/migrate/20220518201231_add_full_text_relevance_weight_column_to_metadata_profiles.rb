class AddFullTextRelevanceWeightColumnToMetadataProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_profiles, :full_text_relevance_weight, :integer, default: 5, null: false
  end
end
