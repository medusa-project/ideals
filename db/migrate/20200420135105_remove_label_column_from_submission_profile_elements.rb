class RemoveLabelColumnFromSubmissionProfileElements < ActiveRecord::Migration[6.0]
  def change
    remove_column :submission_profile_elements, :label
  end
end
