class AddInstitutionIdColumnToEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :institution_id, :bigint, default: 1
    add_foreign_key :events, :institutions, on_update: :cascade, on_delete: :cascade
    change_column_default :events, :institution_id, nil

    add_index :events, :institution_id
    add_index :events, :created_at
  end

  def down
    remove_column :events, :institution_id
  end
end
