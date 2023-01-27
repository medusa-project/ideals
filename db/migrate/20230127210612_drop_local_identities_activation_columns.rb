class DropLocalIdentitiesActivationColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :local_identities, :activated
    remove_column :local_identities, :activated_at
    remove_column :local_identities, :activation_digest
  end
end
