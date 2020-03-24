copy (SELECT sr.short_id, fr.element, fr.qualifier, v.text_value, b.bitstream_id
      FROM metadatavalue v
               LEFT JOIN metadatafieldregistry fr ON fr.metadata_field_id = v.metadata_field_id
               LEFT JOIN metadataschemaregistry sr ON sr.metadata_schema_id = fr.metadata_schema_id
               LEFT JOIN bitstream b ON b.bitstream_id = v.resource_id
      WHERE v.resource_type_id = 0
      ORDER BY b.bitstream_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
