class RenameInviteesNoteToPurpose < ActiveRecord::Migration[7.0]
  def change
    rename_column :invitees, :note, :purpose
  end
end
