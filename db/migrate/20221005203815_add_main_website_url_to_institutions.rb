class AddMainWebsiteUrlToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :main_website_url, :string
  end
end
