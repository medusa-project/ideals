class AddAuthEnabledColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def up
    add_column :institutions, :local_auth_enabled, :boolean, default: true, null: false
    add_column :institutions, :saml_auth_enabled, :boolean, default: false, null: false
    add_column :institutions, :shibboleth_auth_enabled, :boolean, default: false, null: false

    execute "UPDATE institutions SET shibboleth_auth_enabled = true WHERE key = 'uiuc';"
    execute "UPDATE institutions SET saml_auth_enabled = true WHERE key = 'bagel';"

    add_column :institutions, :shibboleth_email_attribute, :string, default: "mail"
    add_column :institutions, :shibboleth_name_attribute, :string, default: "displayName"
    add_column :institutions, :shibboleth_extra_attributes, :text, default: "[]"

    extra_attrs = JSON.generate(%w(eppn unscoped-affiliation uid sn org-dn
                                   nickname givenName member telephoneNumber
                                   iTrustAffiliation departmentName programCode
                                   levelCode))
    execute "UPDATE institutions SET shibboleth_extra_attributes = '#{extra_attrs}' WHERE key = 'uiuc'; "
  end

  def down
    remove_column :institutions, :local_auth_enabled
    remove_column :institutions, :saml_auth_enabled
    remove_column :institutions, :shibboleth_auth_enabled

    remove_column :institutions, :shibboleth_name_attribute
    remove_column :institutions, :shibboleth_email_attribute
    remove_column :institutions, :shibboleth_extra_attributes
  end
end
