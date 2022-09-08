class MoveGlobalUserGroups < ActiveRecord::Migration[7.0]
  def change
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id'] unless id
    execute("UPDATE user_groups SET institution_id = #{id} WHERE key != 'sysadmin';")
  end
end
