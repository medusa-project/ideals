class MakeBitstreamsBundlePositionNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :bitstreams, :bundle_position, true
    change_column_default :bitstreams, :bundle_position, nil
  end
end
