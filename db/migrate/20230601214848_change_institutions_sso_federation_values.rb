class ChangeInstitutionsSsoFederationValues < ActiveRecord::Migration[7.0]
  def change
    execute "UPDATE institutions SET sso_federation = NULL WHERE sso_federation = 0;"
  end
end
