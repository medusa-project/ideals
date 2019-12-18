class CreateInvitees < ActiveRecord::Migration[5.2]
  def change
    create_table :invitees do |t|
      t.string :email, null: false
      t.string :role
      t.datetime :expires_at
      t.boolean :approved, default: false

      t.timestamps null: false
    end
  end
end
