class CreateInviteeNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :invitee_notes do |t|
      t.integer :invitee_id
      t.text :note
      t.string :source

      t.timestamps
    end
  end
end
