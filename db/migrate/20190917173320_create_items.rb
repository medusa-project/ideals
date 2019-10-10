class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :title
      t.string :submitter_email
      t.string :submitter_auth_provider
      t.boolean :in_archive
      t.boolean :withdrawn
      t.integer :collection_id
      t.boolean :discoverable
      t.timestamps
    end
  end
end
