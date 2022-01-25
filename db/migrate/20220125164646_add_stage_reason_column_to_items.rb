class AddStageReasonColumnToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :stage_reason, :text
  end
end
