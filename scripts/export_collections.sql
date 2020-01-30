copy (SELECT c.collection_id, v.text_value as title
    FROM collection c
    INNER JOIN metadatavalue v on (c.collection_id = v.resource_id AND v.resource_type_id=3)
    INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id)
    WHERE r.element = 'title'
    ORDER BY c.collection_id)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
