class RemoveInArchiveColumnFromItems < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :in_archive
  end
end
