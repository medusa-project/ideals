class RedesignInstitutionsSamlIdpSsoServiceUrlColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :saml_idp_sso_service_url, :saml_idp_sso_post_service_url
    add_column :institutions, :saml_idp_sso_redirect_service_url, :string
    execute "UPDATE institutions SET saml_idp_sso_redirect_service_url = saml_idp_sso_post_service_url;"
  end
end
