class AddPlaceholderTextColumnToSubmissionProfileElements < ActiveRecord::Migration[6.0]
  def change
    add_column :submission_profile_elements, :placeholder_text, :text, null: true
  end
end
