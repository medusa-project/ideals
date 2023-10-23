class AddDerivativeGenerationColumnsToBitstreams < ActiveRecord::Migration[7.1]
  def change
    add_column :bitstreams, :derivative_generation_succeeded, :boolean
    add_column :bitstreams, :derivative_generation_attempted_at, :datetime
    add_index :bitstreams, :derivative_generation_succeeded
    add_index :bitstreams, :derivative_generation_attempted_at
  end
end
