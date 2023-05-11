class RemoveInstitutionsSamlIdpEntityIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :saml_idp_entity_id
  end
end
