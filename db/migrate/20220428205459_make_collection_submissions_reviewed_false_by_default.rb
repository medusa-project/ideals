class MakeCollectionSubmissionsReviewedFalseByDefault < ActiveRecord::Migration[7.0]
  def change
    change_column :collections, :submissions_reviewed, :boolean, default: false
  end
end
