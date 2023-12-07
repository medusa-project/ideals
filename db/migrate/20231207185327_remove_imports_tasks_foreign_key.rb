class RemoveImportsTasksForeignKey < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :imports, :tasks
  end
end
