class AddColumnsToMonthlyItemDownloadCounts < ActiveRecord::Migration[7.0]
  def change
    add_column :monthly_item_download_counts, :collection_id, :bigint
    add_column :monthly_item_download_counts, :unit_id, :bigint
    add_column :monthly_item_download_counts, :institution_id, :bigint
    remove_foreign_key :monthly_item_download_counts, :items

    remove_index :monthly_item_download_counts, [:item_id, :year, :month]
    add_index :monthly_item_download_counts,
              [:institution_id, :unit_id, :collection_id, :item_id, :year, :month],
              unique: true,
              name: "index_monthly_item_download_counts_on_model_fks"
    execute "UPDATE monthly_item_download_counts SET collection_id = 0;"
    execute "UPDATE monthly_item_download_counts SET unit_id = 0;"
    execute "UPDATE monthly_item_download_counts SET institution_id = 0;"
    change_column_null :monthly_item_download_counts, :institution_id, false
    change_column_null :monthly_item_download_counts, :unit_id, false
    change_column_null :monthly_item_download_counts, :collection_id, false
    add_index :monthly_item_download_counts, :institution_id
    add_index :monthly_item_download_counts, :unit_id
    add_index :monthly_item_download_counts, :collection_id
    add_index :monthly_item_download_counts, :item_id
  end

end
