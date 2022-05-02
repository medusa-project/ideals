class RenameSubmissionProfileElementsIndexToPosition < ActiveRecord::Migration[7.0]
  def change
    rename_column :submission_profile_elements, :index, :position
  end
end
