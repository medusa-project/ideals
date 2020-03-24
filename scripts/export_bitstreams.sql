copy (SELECT i2b.item_id, b.bitstream_id, b.internal_id, b.deleted,
             b.store_number, b.sequence_id, b.size_bytes, reg.mimetype
      FROM item2bundle i2b
      LEFT JOIN bundle2bitstream b2b ON b2b.bundle_id = i2b.bundle_id
      LEFT JOIN bitstream b ON b2b.bitstream_id = b.bitstream_id
      LEFT JOIN bitstreamformatregistry reg ON reg.bitstream_format_id = b.bitstream_format_id
      ORDER BY i2b.item_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
