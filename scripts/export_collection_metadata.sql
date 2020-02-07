copy (SELECT sr.short_id, fr.element, fr.qualifier, v.text_value, c.collection_id
    FROM metadatavalue v
    LEFT JOIN metadatafieldregistry fr ON fr.metadata_field_id = v.metadata_field_id
    LEFT JOIN metadataschemaregistry sr ON sr.metadata_schema_id = fr.metadata_schema_id
    LEFT JOIN collection c ON c.collection_id = v.resource_id
    WHERE v.resource_type_id = 3
    ORDER BY c.collection_id)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
