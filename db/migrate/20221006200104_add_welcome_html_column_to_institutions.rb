class AddWelcomeHtmlColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :welcome_html, :text
  end
end
