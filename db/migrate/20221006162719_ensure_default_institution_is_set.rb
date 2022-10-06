class EnsureDefaultInstitutionIsSet < ActiveRecord::Migration[7.0]
  def change
    results = execute("SELECT id FROM institutions WHERE \"default\" = true;")
    return if results.any?

    results = execute("SELECT id FROM institutions WHERE key = 'uiuc';")
    if results.any?
      id = results[0]['id']
    else
      id = execute("SELECT id FROM institutions ORDER BY id;")[0]['id']
    end
    execute "UPDATE institutions SET \"default\" = true WHERE id = #{id};"
  end
end
