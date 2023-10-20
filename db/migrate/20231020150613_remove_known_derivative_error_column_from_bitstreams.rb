class RemoveKnownDerivativeErrorColumnFromBitstreams < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:bitstreams, :known_derivative_error)
      remove_column :bitstreams, :known_derivative_error
    end
  end
end
