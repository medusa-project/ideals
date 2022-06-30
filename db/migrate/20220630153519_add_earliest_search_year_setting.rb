class AddEarliestSearchYearSetting < ActiveRecord::Migration[7.0]
  def change
    execute "INSERT INTO settings(key, value, created_at, updated_at) "\
            "VALUES ('earliest_search_year', 1850, NOW(), NOW());"
  end
end
