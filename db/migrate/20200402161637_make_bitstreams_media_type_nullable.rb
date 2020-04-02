class MakeBitstreamsMediaTypeNullable < ActiveRecord::Migration[6.0]
  def change
    change_column :bitstreams, :media_type, :string, null: true
  end
end
