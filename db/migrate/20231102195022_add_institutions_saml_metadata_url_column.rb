class AddInstitutionsSamlMetadataUrlColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :institutions, :saml_metadata_url, :string
  end
end
