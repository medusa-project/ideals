class AddSamlCertValiditySetting < ActiveRecord::Migration[7.0]
  def change
    result = execute "SELECT COUNT(id) AS count FROM settings WHERE key = 'saml_cert.validity_years';"
    if result[0]['count'] < 1
      execute "INSERT INTO settings(key, value, created_at, updated_at)
               VALUES('saml_cert.validity_years', '10', NOW(), NOW());"
    end
  end
end
