class AddInstitutionIdColumnToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :institution_id, :bigint
    execute "UPDATE messages
             SET institution_id = (
                SELECT institution_id
                FROM bitstreams
                WHERE bitstreams.id = messages.bitstream_id
             );"
    execute "UPDATE messages
             SET institution_id = (
                SELECT id
                FROM institutions
                WHERE institutions.key = 'uiuc'
             )
             WHERE messages.institution_id IS NULL;"
    change_column_null :messages, :institution_id, false
    add_foreign_key :messages, :institutions, on_update: :cascade, on_delete: :cascade
    add_index :messages, :institution_id
  end
end
