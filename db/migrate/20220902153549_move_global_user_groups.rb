class MoveGlobalUserGroups < ActiveRecord::Migration[7.0]
  def change
    id = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    execute("UPDATE user_groups SET institution_id = #{id} WHERE key != 'sysadmin';")
  end
end
