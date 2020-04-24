class AddUniqueKeysOnIdentitiesEmailAndInviteesEmail < ActiveRecord::Migration[6.0]
  def change
    add_index :identities, :email, unique: true
    add_index :invitees, :email, unique: true
  end
end
