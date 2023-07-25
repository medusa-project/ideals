class AddPublicReasonColumnToEmbargoes < ActiveRecord::Migration[7.0]
  def change
    add_column :embargoes, :public_reason, :text
  end
end
