class ChangeImportsCollectionsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :imports, :collections
    add_foreign_key :imports, :collections, on_update: :cascade, on_delete: :cascade
  end
end
