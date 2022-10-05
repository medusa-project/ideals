class AddThemeImageColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :header_image_filename, :string
    add_column :institutions, :footer_image_filename, :string
  end
end
