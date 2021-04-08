copy (SELECT bitstream_id, month, count
      FROM monthly_bitstream_stats)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
