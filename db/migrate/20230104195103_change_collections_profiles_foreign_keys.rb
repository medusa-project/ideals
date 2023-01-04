class ChangeCollectionsProfilesForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :collections, :metadata_profiles
    remove_foreign_key :collections, :submission_profiles
    add_foreign_key :collections, :metadata_profiles, on_update: :cascade, on_delete: :nullify
    add_foreign_key :collections, :submission_profiles, on_update: :cascade, on_delete: :nullify
  end
end
