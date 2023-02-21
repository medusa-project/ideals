class MakeBitstreamsFilenamesNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :bitstreams, :original_filename, false
    change_column_null :bitstreams, :filename, false
  end
end
