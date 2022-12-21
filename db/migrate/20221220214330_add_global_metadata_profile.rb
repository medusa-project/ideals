class AddGlobalMetadataProfile < ActiveRecord::Migration[7.0]
  def change
    change_column_null :metadata_profiles, :institution_id, true
    change_column_null :registered_elements, :institution_id, true

    execute("INSERT INTO registered_elements(name, label, input_type, highwire_mapping, created_at, updated_at)
             VALUES ('dc:creator', 'Creator', 'text_field', 'citation_author', NOW(), NOW()),
                    ('dc:subject', 'Keywords', 'text_field', 'citation_keywords', NOW(), NOW()),
                    ('dc:type', 'Type of Resource', 'text_field', NULL, NOW(), NOW())
             ;")

    execute("INSERT INTO metadata_profiles(name, \"default\", institution_id, full_text_relevance_weight, created_at, updated_at)
             VALUES('Global Profile', false, NULL, 5, NOW(), NOW());")
    profile_id = execute("SELECT id FROM metadata_profiles WHERE institution_id IS NULL;")[0]['id']

    id = execute("SELECT id FROM registered_elements
                  WHERE institution_id IS NULL AND name = 'dc:creator';")[0]['id']
    execute("INSERT INTO metadata_profile_elements(metadata_profile_id, registered_element_id, position, relevance_weight, visible, searchable, sortable, faceted, created_at, updated_at)
             VALUES(#{profile_id}, #{id}, 0, 5, true, true, true, true, NOW(), NOW());")

    id = execute("SELECT id FROM registered_elements
                  WHERE institution_id IS NULL AND name = 'dc:subject';")[0]['id']
    execute("INSERT INTO metadata_profile_elements(metadata_profile_id, registered_element_id, position, relevance_weight, visible, searchable, sortable, faceted, created_at, updated_at)
             VALUES(#{profile_id}, #{id}, 1, 5, true, true, false, true, NOW(), NOW());")

    id = execute("SELECT id FROM registered_elements
                  WHERE institution_id IS NULL AND name = 'dc:type';")[0]['id']
    execute("INSERT INTO metadata_profile_elements(metadata_profile_id, registered_element_id, position, relevance_weight, visible, searchable, sortable, faceted, created_at, updated_at)
             VALUES(#{profile_id}, #{id}, 2, 5, true, true, true, true, NOW(), NOW());")
  end
end

