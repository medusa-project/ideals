class AddEnabledColumnOnUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :enabled, :boolean, default: true, null: false
  end
end
