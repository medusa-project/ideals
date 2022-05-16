copy (SELECT v.text_value, b2b.bitstream_id
      FROM metadatavalue v
      INNER JOIN bundle2bitstream b2b ON b2b.bundle_id = v.resource_id
      WHERE v.resource_type_id = 1
      ORDER BY b2b.bitstream_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
