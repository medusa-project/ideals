class RemoveInstitutionShibbolethColumns < ActiveRecord::Migration[7.1]
  def up
    remove_column :institutions, :shibboleth_org_dn
    remove_column :institutions, :shibboleth_auth_enabled
    remove_column :institutions, :shibboleth_email_attribute
    remove_column :institutions, :shibboleth_extra_attributes
    remove_column :institutions, :shibboleth_name_attribute
  end
  def down
    add_column :institutions, :shibboleth_org_dn, :string
    add_column :institutions, :shibboleth_auth_enabled, :string
    add_column :institutions, :shibboleth_email_attribute, :string
    add_column :institutions, :shibboleth_extra_attributes, :string
    add_column :institutions, :shibboleth_name_attribute, :string
  end
end
