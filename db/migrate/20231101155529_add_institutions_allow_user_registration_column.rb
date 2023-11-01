class AddInstitutionsAllowUserRegistrationColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :institutions, :allow_user_registration, :boolean, default: true, null: false
    execute "UPDATE institutions SET allow_user_registration = false WHERE key = 'uiuc';"
  end
end
