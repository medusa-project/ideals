class AddUniqueIndexesOnUsers < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :email, unique: true
    add_index :users, :uid, unique: true
    add_index :users, :username, unique: true

    add_index :users, :name # for searching maybe

    change_column_null :users, :email, false
    change_column_null :users, :name, false
    change_column_null :users, :type, false
    change_column_null :users, :uid, false
    change_column_null :users, :username, false
  end
end
