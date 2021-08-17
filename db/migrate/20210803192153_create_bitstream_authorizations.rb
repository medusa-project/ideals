class CreateBitstreamAuthorizations < ActiveRecord::Migration[6.0]
  def change
    create_table :bitstream_authorizations do |t|
      t.bigint :item_id, null: false
      t.bigint :user_group_id, null: false

      t.timestamps
    end
    add_foreign_key :bitstream_authorizations, :items, on_update: :cascade, on_delete: :cascade
    add_foreign_key :bitstream_authorizations, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
