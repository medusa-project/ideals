class MakeUsersInstitutionIdNotNull < ActiveRecord::Migration[7.0]
  def change
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    execute "UPDATE users SET institution_id = #{id} WHERE institution_id IS NULL;"
    change_column_null :users, :institution_id, false
  end
end
