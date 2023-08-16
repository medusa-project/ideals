class RemoveMessagesBitstreamsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :messages, :bitstreams
  end
end
