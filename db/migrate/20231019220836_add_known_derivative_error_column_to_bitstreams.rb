class AddKnownDerivativeErrorColumnToBitstreams < ActiveRecord::Migration[7.1]
  def change
    add_column :bitstreams, :known_derivative_error, :boolean, null: false, default: false
  end
end
