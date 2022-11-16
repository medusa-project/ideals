class AddHasFaviconColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :has_favicon, :boolean, default: false, null: false
  end
end
