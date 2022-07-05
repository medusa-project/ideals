class CreateMonthlyUnitItemDownloadCounts < ActiveRecord::Migration[7.0]
  def change
    create_table :monthly_unit_item_download_counts do |t|
      t.bigint :unit_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :count, null: false

      t.timestamps
    end
    add_index :monthly_unit_item_download_counts,
              [:unit_id, :year, :month], unique: true,
              name: "index_monthly_unit_item_download_counts_unique"
    add_index :monthly_unit_item_download_counts, :unit_id
    add_index :monthly_unit_item_download_counts, :year
    add_index :monthly_unit_item_download_counts, :month
  end
end
