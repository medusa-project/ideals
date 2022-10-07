class AddBannerImageFilenameColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :banner_image_filename, :string
  end
end
