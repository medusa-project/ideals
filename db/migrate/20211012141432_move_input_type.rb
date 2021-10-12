class MoveInputType < ActiveRecord::Migration[6.0]
  def change
    add_column :registered_elements, :input_type, :string
    execute "UPDATE registered_elements SET input_type = 'text_field' WHERE vocabulary_key IS NULL;"
    execute "UPDATE registered_elements SET input_type = 'text_area' WHERE name LIKE 'dc:description%'"

    remove_column :submission_profile_elements, :input_type
  end
end
