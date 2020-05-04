class MakeInviteesExpiresAtNotNull < ActiveRecord::Migration[6.0]
  def change
    execute "UPDATE invitees SET expires_at = NOW() WHERE expires_at IS NULL;"
    change_column_null :invitees, :expires_at, false
  end
end
