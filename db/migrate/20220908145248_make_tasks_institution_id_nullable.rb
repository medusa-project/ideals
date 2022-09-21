class MakeTasksInstitutionIdNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :tasks, :institution_id, true
  end
end
