class AddEarliestSearchYearColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :earliest_search_year, :integer, null: false, default: 2000
    execute "UPDATE institutions SET earliest_search_year = 1850 WHERE key = 'uiuc';"
  end
end
