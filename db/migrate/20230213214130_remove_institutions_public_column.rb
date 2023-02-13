class RemoveInstitutionsPublicColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :public
  end
end
