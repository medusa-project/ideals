class AddAuthMethodToLogins < ActiveRecord::Migration[7.0]
  def change
    add_column :logins, :auth_method, :integer
    results = execute "SELECT id, auth_hash FROM logins WHERE auth_hash IS NOT NULL AND LENGTH(auth_hash) > 5;"
    results.each do |row|
      provider = row['auth_hash'][0..50].scan(/"provider":"(\w+)",/).first&.first
      case provider
      when "saml"
        method = 2 # SAML
      when "shibboleth", "developer"
        method = 1 # Shibboleth
      when "identity"
        method = 0 # local
      else
        raise "Unknown provider: #{provider}\n\n#{row['auth_hash']}"
      end
      execute "UPDATE logins SET auth_method = #{method} WHERE id = #{row['id']};"
    end
  end
end
