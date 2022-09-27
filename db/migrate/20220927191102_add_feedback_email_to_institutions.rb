class AddFeedbackEmailToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :feedback_email, :string
    execute "UPDATE institutions SET feedback_email = 'IDEALS @ Illinois <ideals@library.illinois.edu>' WHERE key = 'uiuc';"
  end
end
