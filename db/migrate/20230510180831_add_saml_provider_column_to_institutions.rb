class AddSamlProviderColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_provider, :integer
  end
end
