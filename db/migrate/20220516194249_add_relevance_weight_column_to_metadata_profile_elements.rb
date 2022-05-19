class AddRelevanceWeightColumnToMetadataProfileElements < ActiveRecord::Migration[7.0]
  def change
    add_column :metadata_profile_elements, :relevance_weight, :integer, default: 5, null: false
  end
end
