copy (SELECT t.community_id, v.text_value
    FROM community t
    INNER JOIN metadatavalue v on (t.community_id = v.resource_id and v.resource_type_id = 4)
    INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id)
    WHERE r.element = 'title'
    ORDER BY t.community_id)
to '/tmp/communities.csv' WITH DELIMITER '|' CSV HEADER;

copy (SELECT child_comm_id as group_id, parent_comm_id as parent_unit_id
    FROM community2community
    ORDER BY child_comm_id)
to '/tmp/community2community.csv' WITH DELIMITER '|' CSV HEADER;