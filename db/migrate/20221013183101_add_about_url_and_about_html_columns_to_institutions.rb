class AddAboutUrlAndAboutHtmlColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :about_url, :string
    add_column :institutions, :about_html, :text
  end
end
