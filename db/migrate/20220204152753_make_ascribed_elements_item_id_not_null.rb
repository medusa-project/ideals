class MakeAscribedElementsItemIdNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :ascribed_elements, :item_id, false
  end
end
