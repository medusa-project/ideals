class AddNoteToInvitee < ActiveRecord::Migration[5.2]
  def change
    add_column :invitees, :note, :text
  end
end
