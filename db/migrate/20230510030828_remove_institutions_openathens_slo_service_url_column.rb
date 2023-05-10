class RemoveInstitutionsOpenathensSloServiceUrlColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :institutions, :openathens_idp_slo_service_url
  end
end
