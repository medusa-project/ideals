class CreateIdentities < ActiveRecord::Migration[5.2]
  def change
    create_table :identities do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest
      t.string :activation_digest
      t.boolean :activated, default: false
      t.datetime :activated_at
      t.string :reset_digest
      t.integer :invitee_id
      t.datetime :reset_sent_at

      t.timestamps null: false
    end
  end
end
