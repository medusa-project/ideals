copy (SELECT v.text_value, b.bitstream_id
      FROM metadatavalue v
            LEFT JOIN bitstream b ON b.bitstream_id = v.resource_id
      WHERE v.resource_type_id = 1
      ORDER BY b.bitstream_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
