class AddPublicColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists? :institutions, :public
      add_column :institutions, :public, :boolean, default: true, null: false
      add_index :institutions, :public
    end
  end
end
