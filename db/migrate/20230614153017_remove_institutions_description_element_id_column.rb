class RemoveInstitutionsDescriptionElementIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :description_element_id
  end
end
