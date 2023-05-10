class RenameInstitutionsOpenathensColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :institutions, :openathens_sp_entity_id, :saml_sp_entity_id
    add_column :institutions, :saml_idp_entity_id, :string
    rename_column :institutions, :openathens_email_attribute, :saml_email_attribute
    rename_column :institutions, :openathens_first_name_attribute, :saml_first_name_attribute
    rename_column :institutions, :openathens_last_name_attribute, :saml_last_name_attribute
    rename_column :institutions, :openathens_idp_cert, :saml_idp_cert
    rename_column :institutions, :openathens_idp_sso_service_url, :saml_idp_sso_service_url
  end
end
