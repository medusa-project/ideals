copy (SELECT u.eperson_id, r.element, v.text_value
      FROM eperson u
               LEFT JOIN metadatavalue v ON v.resource_id = u.eperson_id
               LEFT JOIN metadatafieldregistry r ON r.metadata_field_id = v.metadata_field_id
      WHERE v.resource_type_id = 7
        AND u.eperson_id NOT IN (####)
      ORDER BY u.eperson_id, r.element)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
