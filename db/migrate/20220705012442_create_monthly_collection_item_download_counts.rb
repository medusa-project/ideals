class CreateMonthlyCollectionItemDownloadCounts < ActiveRecord::Migration[7.0]
  def change
    create_table :monthly_collection_item_download_counts do |t|
      t.bigint :collection_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :count, null: false

      t.timestamps
    end
    add_index :monthly_collection_item_download_counts,
              [:collection_id, :year, :month], unique: true,
              name: "index_monthly_col_item_download_counts_unique"
    add_index :monthly_collection_item_download_counts, :collection_id,
              name: "index_monthly_col_item_download_counts_on_col_id"
    add_index :monthly_collection_item_download_counts, :year
    add_index :monthly_collection_item_download_counts, :month
  end
end
