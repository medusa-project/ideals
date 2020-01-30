copy (SELECT t.community_id, v.text_value
    FROM community t
    INNER JOIN metadatavalue v on (t.community_id = v.resource_id and v.resource_type_id = 4)
    INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id)
    WHERE r.element = 'title'
    ORDER BY t.community_id)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
