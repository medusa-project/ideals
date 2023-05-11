class AddSamlEmailLocationColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_email_location, :integer
  end
end
