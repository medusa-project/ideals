copy (SELECT sr.short_id, fr.element, fr.qualifier, REGEXP_REPLACE(v.text_value, E'[\r\n]+', '@@@@', 'g'), i.item_id, v.place
    FROM metadatavalue v
    LEFT JOIN metadatafieldregistry fr ON fr.metadata_field_id = v.metadata_field_id
    LEFT JOIN metadataschemaregistry sr ON sr.metadata_schema_id = fr.metadata_schema_id
    LEFT JOIN item i ON i.item_id = v.resource_id
    WHERE v.resource_type_id = 2
    ORDER BY i.item_id, sr.short_id, fr.element, fr.qualifier, v.place)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
