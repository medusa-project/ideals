class MoveGlobalUserGroups < ActiveRecord::Migration[7.0]
  def change
    results = execute("SELECT id FROM institutions WHERE key = 'uiuc';")
    if results.any?
      id = results[0]['id']
    else
      id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id']
    end
    execute("UPDATE user_groups SET institution_id = #{id} WHERE key != 'sysadmin';")
  end
end
