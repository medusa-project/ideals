class AddMedusaFileGroupIdColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :medusa_file_group_id, :integer
    add_index :institutions, :medusa_file_group_id, unique: true
    if Rails.env.demo?
      execute "UPDATE institutions SET medusa_file_group_id = 243 WHERE key = 'uiuc';"
    elsif Rails.env.production?
      execute "UPDATE institutions SET medusa_file_group_id = 5431 WHERE key = 'uiuc';"
    end
  end
end
