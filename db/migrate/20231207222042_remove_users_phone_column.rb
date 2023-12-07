class RemoveUsersPhoneColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :phone
  end
end
