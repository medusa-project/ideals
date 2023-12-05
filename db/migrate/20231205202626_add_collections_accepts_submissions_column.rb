class AddCollectionsAcceptsSubmissionsColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :collections, :accepts_submissions, :boolean, default: true, null: false
    add_index :collections, :accepts_submissions
  end
end
