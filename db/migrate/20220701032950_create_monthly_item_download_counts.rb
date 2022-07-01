class CreateMonthlyItemDownloadCounts < ActiveRecord::Migration[7.0]
  def change
    create_table :monthly_item_download_counts do |t|
      t.bigint :item_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :count, null: false

      t.timestamps
    end
    add_foreign_key :monthly_item_download_counts, :items,
                    on_update: :cascade, on_delete: :cascade
    add_index :monthly_item_download_counts, [:item_id, :year, :month],
              unique: true,
              name: "index_monthly_item_download_counts_on_item_id_year_month"
  end
end
