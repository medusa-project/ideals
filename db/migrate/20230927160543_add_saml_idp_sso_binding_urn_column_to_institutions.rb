class AddSamlIdpSsoBindingUrnColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :saml_idp_sso_binding_urn, :string,
               default: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
  end
end
