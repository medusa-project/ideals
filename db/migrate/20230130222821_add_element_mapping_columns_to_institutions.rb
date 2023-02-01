class AddElementMappingColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :title_element_id, :bigint
    add_column :institutions, :author_element_id, :bigint
    add_column :institutions, :description_element_id, :bigint
    add_column :institutions, :date_submitted_element_id, :bigint
    add_column :institutions, :date_approved_element_id, :bigint
    add_column :institutions, :date_published_element_id, :bigint
    add_column :institutions, :handle_uri_element_id, :bigint
    add_foreign_key :institutions, :registered_elements,
                    column: :title_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :author_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :description_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :date_submitted_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :date_approved_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :date_published_element_id,
                    on_update: :cascade, on_delete: :restrict
    add_foreign_key :institutions, :registered_elements,
                    column: :handle_uri_element_id,
                    on_update: :cascade, on_delete: :restrict

    uiuc_id         = execute("SELECT id FROM institutions WHERE key = 'uiuc';")[0]['id']
    institution_ids = execute("SELECT id FROM institutions;").map{ |r| r['id'] }
    # We will do UIUC differently after this loop
    institution_ids.reject{ |id| id == uiuc_id }.each do |institution_id|
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:title';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'dc:title', 'Title', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:creator';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'dc:creator', 'Creator', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:description';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'dc:description', 'Description', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:submitted';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'ideals:date:submitted', 'Date Submitted', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:approved';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'ideals:date:approved', 'Date Approved', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:published';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'ideals:date:published', 'Date Published', NOW(), NOW());")
      end
      if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:handleURI';")[0]['count']
        execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{institution_id}, 'ideals:handleURI', 'Handle URI', NOW(), NOW());")
      end

      # Get element IDs
      title_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:title';")[0]['id']
      author_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:creator';")[0]['id']
      description_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'dc:description';")[0]['id']
      date_submitted_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:submitted';")[0]['id']
      date_approved_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:approved';")[0]['id']
      date_published_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:date:published';")[0]['id']
      handle_uri_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{institution_id} AND name = 'ideals:handleURI';")[0]['id']

      # Set mappings
      execute("UPDATE institutions SET title_element_id = #{title_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET author_element_id = #{author_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET description_element_id = #{description_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET date_submitted_element_id = #{date_submitted_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET date_approved_element_id = #{date_approved_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET date_published_element_id = #{date_published_element_id}
               WHERE id = #{institution_id};")
      execute("UPDATE institutions SET handle_uri_element_id = #{handle_uri_element_id}
               WHERE id = #{institution_id};")
    end

    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:title';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'dc:title', 'Title', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:creator';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'dc:creator', 'Creator', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:description';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'dc:description', 'Description', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'ideals:date:submitted';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'ideals:date:submitted', 'Date Submitted', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'ideals:date:approved';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'ideals:date:approved', 'Date Approved', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'ideals:date:published';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'ideals:date:published', 'Date Published', NOW(), NOW());")
    end
    if 1 > execute("SELECT COUNT(id) AS count FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'ideals:handleURI';")[0]['count']
      execute("INSERT INTO registered_elements(institution_id, name, label, created_at, updated_at)
               VALUES(#{uiuc_id}, 'ideals:handleURI', 'Handle URI', NOW(), NOW());")
    end

    # Get UIUC element IDs
    title_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:title';")[0]['id']
    author_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:creator';")[0]['id']
    description_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:description';")[0]['id']
    date_submitted_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:date:submitted';")[0]['id']
    date_approved_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dcterms:available';")[0]['id']
    date_published_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dc:date:issued';")[0]['id']
    handle_uri_element_id = execute("SELECT id FROM registered_elements
          WHERE institution_id = #{uiuc_id} AND name = 'dcterms:identifier';")[0]['id']

    # Set UIUC mappings
    execute("UPDATE institutions SET title_element_id = #{title_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET author_element_id = #{author_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET description_element_id = #{description_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET date_submitted_element_id = #{date_submitted_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET date_approved_element_id = #{date_approved_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET date_published_element_id = #{date_published_element_id}
               WHERE id = #{uiuc_id};")
    execute("UPDATE institutions SET handle_uri_element_id = #{handle_uri_element_id}
               WHERE id = #{uiuc_id};")

    change_column_null :institutions, :title_element_id, false
    change_column_null :institutions, :author_element_id, false
    change_column_null :institutions, :description_element_id, false
  end
end
