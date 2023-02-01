class RemoveInstitutionsDefault < ActiveRecord::Migration[7.0]
  def up
    remove_column :institutions, :default if column_exists?(:institutions, :default)
  end
  def down
    add_column :institutions, :default, :boolean, default: false, null: false
    execute "UPDATE institutions SET \"default\" = true WHERE key = 'uiuc';"
  end
end
