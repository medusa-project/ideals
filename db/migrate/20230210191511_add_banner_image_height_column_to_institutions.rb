class AddBannerImageHeightColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :banner_image_height, :integer, null: false, default: 200
  end
end
