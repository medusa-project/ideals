class MoveBitstreamsFullTextColumnToNewTable < ActiveRecord::Migration[7.0]
  def up
    create_table :full_texts do |t|
      t.bigint :bitstream_id, null: false
      t.text :text, null: true

      t.timestamps
    end
    add_index :full_texts, :bitstream_id, unique: true
    add_foreign_key :full_texts, :bitstreams, on_update: :cascade, on_delete: :cascade

    execute "INSERT INTO full_texts(bitstream_id, text, created_at, updated_at) "\
            "SELECT id, full_text, NOW(), NOW() "\
            "FROM bitstreams "\
            "WHERE full_text IS NOT NULL AND LENGTH(full_text) > 0;"
    remove_column :bitstreams, :full_text
  end

  def down
    add_column :bitstreams, :full_text, :text, null: true
    execute "UPDATE bitstreams "\
            "SET full_text = ft.text "\
            "FROM full_texts ft "\
            "WHERE ft.bitstream_id = bitstreams.id;"
    drop_table :full_texts
  end
end
