class RenameInstitutionsSamlProviderToFederation < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :saml_provider, :sso_federation
  end
end