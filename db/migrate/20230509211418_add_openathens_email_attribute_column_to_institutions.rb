class AddOpenathensEmailAttributeColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :openathens_email_attribute, :string
    add_column :institutions, :openathens_first_name_attribute, :string
    add_column :institutions, :openathens_last_name_attribute, :string
  end
end
