class AddLiveColumnToInstitutions < ActiveRecord::Migration[7.1]
  def change
    add_column :institutions, :live, :boolean, default: false, null: false
    execute "UPDATE institutions SET live = true;"
  end
end
