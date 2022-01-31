copy (SELECT r.metadata_field_id, s.short_id, r.element,
             r.qualifier, regexp_replace(r.scope_note, E'[\\n\\r\\t]', '', 'g')
      FROM metadatafieldregistry r
      LEFT JOIN metadataschemaregistry s ON s.metadata_schema_id = r.metadata_schema_id
      WHERE metadata_field_id NOT IN (####))
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
