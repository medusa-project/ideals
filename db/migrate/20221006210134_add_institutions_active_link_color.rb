class AddInstitutionsActiveLinkColor < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :active_link_color, :string, default: "#23527c", null: false
    execute "UPDATE institutions SET active_link_color = link_hover_color;"
  end
end
