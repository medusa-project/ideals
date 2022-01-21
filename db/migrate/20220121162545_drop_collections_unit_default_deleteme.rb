class DropCollectionsUnitDefaultDeleteme < ActiveRecord::Migration[7.0]
  def change
    remove_column :collections, :unit_default_deleteme
  end
end
