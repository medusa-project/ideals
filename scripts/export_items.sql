/*
challenge: titles have commas in them, hence the pipe delimiter
TODO: some items have multiple titles - just using the first for this toy data - not a real solution
*/
copy (SELECT i.item_id, p.email, i.in_archive, i.withdrawn, i.owning_collection, i.discoverable, v.text_value
    FROM item i
    INNER JOIN metadatavalue v on (i.item_id = v.resource_id)
    INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id)
    INNER JOIN eperson p on (i.submitter_id = p.eperson_id)
    WHERE v.resource_type_id = 2
      AND r.element = 'title'
    ORDER BY i.item_id)
to '/tmp/items.csv' WITH DELIMITER '|' CSV HEADER;

