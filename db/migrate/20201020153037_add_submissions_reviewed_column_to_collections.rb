class AddSubmissionsReviewedColumnToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :submissions_reviewed, :boolean, null: false, default: true
  end
end
