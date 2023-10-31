class AddBitstreamsMessagesForeignKey < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :messages, :bitstreams, on_update: :cascade, on_delete: :cascade
  end
end
