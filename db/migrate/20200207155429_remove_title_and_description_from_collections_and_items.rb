class RemoveTitleAndDescriptionFromCollectionsAndItems < ActiveRecord::Migration[6.0]
  def change
    remove_column :collections, :title
    remove_column :collections, :description
    remove_column :items, :title
  end
end
