class AddPreviousStageColumnToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :previous_stage, :integer
    add_column :items, :previous_stage_reason, :text
  end
end
