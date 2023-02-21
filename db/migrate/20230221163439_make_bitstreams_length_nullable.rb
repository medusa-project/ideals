class MakeBitstreamsLengthNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :bitstreams, :length, true
  end
end
