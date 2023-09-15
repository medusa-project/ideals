class AddSubmissionsReviewedColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :submissions_reviewed, :boolean, default: true, null: false
    execute "UPDATE institutions SET submissions_reviewed = false WHERE key = 'uiuc';"
  end
end
