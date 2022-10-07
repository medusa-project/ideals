class AddCopyrightNoticeColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :copyright_notice, :string
  end
end
