class AddInputTypeColumnToSubmissionProfileElements < ActiveRecord::Migration[6.0]
  def change
    add_column :submission_profile_elements, :input_type, :string
  end
end
