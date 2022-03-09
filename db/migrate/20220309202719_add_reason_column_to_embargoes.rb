class AddReasonColumnToEmbargoes < ActiveRecord::Migration[7.0]
  def change
    add_column :embargoes, :reason, :text
  end
end
