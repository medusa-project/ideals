class AddDescriptionColumnsToUnitsAndCollections < ActiveRecord::Migration[6.0]
  def up
    add_column :collections, :title, :string
    add_column :collections, :description, :text
    add_column :collections, :short_description, :text
    add_column :collections, :introduction, :text
    add_column :collections, :rights, :text
    add_column :collections, :provenance, :text
    add_column :units, :short_description, :text
    add_column :units, :introduction, :text
    add_column :units, :rights, :text
    execute "DELETE FROM ascribed_elements WHERE collection_id IS NOT NULL;"
    remove_column :ascribed_elements, :collection_id
  end
  def down
    remove_column :collections, :description
    remove_column :collections, :short_description
    remove_column :collections, :introduction
    remove_column :collections, :rights
    remove_column :collections, :provenance
    remove_column :collections, :title
    remove_column :units, :short_description
    remove_column :units, :introduction
    remove_column :units, :rights
    add_column :ascribed_elements, :collection_id, :bigint
  end
end
