class MakeInstitutionColorColumnsNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :institutions, :footer_background_color, false
    change_column_null :institutions, :header_background_color, false
    change_column_null :institutions, :link_color, false
    change_column_null :institutions, :link_hover_color, false
    change_column_null :institutions, :primary_color, false
    change_column_null :institutions, :primary_hover_color, false
  end
end
