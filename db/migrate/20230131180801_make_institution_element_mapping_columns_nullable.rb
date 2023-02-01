class MakeInstitutionElementMappingColumnsNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :institutions, :title_element_id, true
    change_column_null :institutions, :author_element_id, true
    change_column_null :institutions, :description_element_id, true
  end
end
