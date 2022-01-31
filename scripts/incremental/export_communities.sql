copy (SELECT v.resource_id, r.element, r.qualifier, REGEXP_REPLACE(v.text_value, E'[\r\n]+', '@@@@', 'g')
      FROM metadatavalue v
      INNER JOIN metadatafieldregistry r ON (v.metadata_field_id = r.metadata_field_id)
      WHERE v.resource_type_id = 4
      AND v.resource_id NOT IN (####)
      ORDER BY v.resource_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
