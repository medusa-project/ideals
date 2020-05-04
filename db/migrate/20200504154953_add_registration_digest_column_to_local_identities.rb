class AddRegistrationDigestColumnToLocalIdentities < ActiveRecord::Migration[6.0]
  def change
    add_column :local_identities, :registration_digest, :string
  end
end
