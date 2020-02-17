class RedesignItemSubmitterColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :submitter_auth_provider
    remove_column :items, :submitter_email

    add_column :items, :submitter_id, :bigint
    add_foreign_key :items, :users, column: :submitter_id,
                    on_update: :cascade, on_delete: :restrict
  end
end
