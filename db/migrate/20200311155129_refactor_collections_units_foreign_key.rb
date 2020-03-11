class RefactorCollectionsUnitsForeignKey < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :collections_units, :collections
    add_foreign_key :collections_units, :collections,
                    on_update: :cascade, on_delete: :cascade
  end
end
