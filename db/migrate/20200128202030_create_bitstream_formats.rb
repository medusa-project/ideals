class CreateBitstreamFormats < ActiveRecord::Migration[6.0]
  def change
    create_table :bitstream_formats do |t|
      t.string :media_type, null: false
      t.text :short_description, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :bitstream_formats, :media_type, unique: true

    remove_column :bitstreams, :media_type
    add_column :bitstreams, :bitstream_format_id, :integer
    add_foreign_key :bitstreams, :bitstream_formats, on_update: :cascade, on_delete: :restrict
  end
end
