class RemoveInstitutionsDatePublishedElementIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :date_published_element_id
  end
end
