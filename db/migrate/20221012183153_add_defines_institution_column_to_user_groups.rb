class AddDefinesInstitutionColumnToUserGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :user_groups, :defines_institution, :boolean, required: true, default: false
    execute "UPDATE user_groups SET defines_institution = true WHERE key = 'uiuc';"
  end
end
