class MakeInviteesNoteColumnNotNull < ActiveRecord::Migration[6.0]
  def change
    execute "UPDATE invitees SET note = 'Not provided' WHERE note IS NULL;"
    change_column_null :invitees, :note, false
  end
end
