class ChangeInstitutionsSamlIdpSsoBindingUrnDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :institutions, :saml_idp_sso_binding_urn,
                          "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
  end
end
