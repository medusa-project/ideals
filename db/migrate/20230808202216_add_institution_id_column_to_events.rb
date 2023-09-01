class AddInstitutionIdColumnToEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :institution_id, :bigint
    add_foreign_key :events, :institutions, on_update: :cascade, on_delete: :cascade

    # Items
    results = execute("SELECT DISTINCT e.item_id, i.institution_id
                       FROM events e
                       LEFT JOIN items i ON e.item_id = i.id
                       WHERE e.item_id IS NOT NULL AND i.institution_id IS NOT NULL;")
    map = {}
    results.each do |row|
      map[row['institution_id']] = [] if map[row['institution_id']].nil?
      map[row['institution_id']] << row['item_id']
    end
    map.each do |institution_id, item_ids|
      execute("UPDATE events SET institution_id = #{institution_id}
               WHERE item_id IN (#{item_ids.join(",")});")
    end

    # Bitstreams
    results = execute("SELECT DISTINCT e.bitstream_id, i.institution_id
                       FROM events e
                       LEFT JOIN bitstreams b ON e.bitstream_id = b.id
                       LEFT JOIN items i ON b.item_id = i.id
                       WHERE e.bitstream_id IS NOT NULL AND i.institution_id IS NOT NULL;")
    map = {}
    results.each do |row|
      map[row['institution_id']] = [] if map[row['institution_id']].nil?
      map[row['institution_id']] << row['bitstream_id']
    end
    map.each do |institution_id, bitstream_ids|
      execute("UPDATE events SET institution_id = #{institution_id}
               WHERE bitstream_id IN (#{bitstream_ids.join(",")});")
    end

    # Logins
    results = execute("SELECT DISTINCT e.login_id, u.institution_id
                       FROM events e
                       LEFT JOIN logins l ON l.id = e.login_id
                       LEFT JOIN users u ON l.user_id = u.id
                       WHERE e.login_id IS NOT NULL;")
    map = {}
    results.each do |row|
      map[row['institution_id']] = [] if map[row['institution_id']].nil?
      map[row['institution_id']] << row['login_id']
    end
    map.each do |institution_id, login_ids|
      execute("UPDATE events SET institution_id = #{institution_id}
               WHERE login_id IN (#{login_ids.join(",")});")
    end

    add_index :events, :institution_id
    add_index :events, :created_at
  end

  def down
    remove_column :events, :institution_id
  end
end
