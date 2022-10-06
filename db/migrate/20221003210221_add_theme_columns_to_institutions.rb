class AddThemeColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def up
    add_column :institutions, :footer_background_color, :string, default: "#13294b"
    add_column :institutions, :header_background_color, :string, default: "#13294b"
    add_column :institutions, :link_color, :string, default: "#23527c"
    add_column :institutions, :link_hover_color, :string, default: "#23527c"
    add_column :institutions, :primary_color, :string, default: "#23527c"
    add_column :institutions, :primary_hover_color, :string, default: "#05325b"

    execute "UPDATE institutions
             SET footer_background_color = '#13294b',
                 header_background_color = '#13294b',
                 link_color = '#23527c',
                 link_hover_color = '#23527c',
                 primary_color = '#23527c',
                 primary_hover_color = '#05325b';"
  end

  def down
    remove_column :institutions, :footer_background_color
    remove_column :institutions, :header_background_color
    remove_column :institutions, :link_color
    remove_column :institutions, :link_hover_color
    remove_column :institutions, :primary_color
    remove_column :institutions, :primary_hover_color
  end
end
