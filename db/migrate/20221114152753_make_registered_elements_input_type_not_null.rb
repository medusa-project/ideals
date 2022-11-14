class MakeRegisteredElementsInputTypeNotNull < ActiveRecord::Migration[7.0]
  def up
    execute "UPDATE registered_elements SET input_type = 'text_field' WHERE input_type IS NULL;"
    change_column_default :registered_elements, :input_type, "text_field"
    change_column_null :registered_elements, :input_type, false
  end
  def down
    change_column_null :registered_elements, :input_type, true
    change_column_default :registered_elements, :input_type, nil
  end
end
