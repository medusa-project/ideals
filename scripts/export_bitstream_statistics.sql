copy (SELECT bitstream_id, month, count, monthly_bitstream_stats_id
      FROM monthly_bitstream_stats
      WHERE monthly_bitstream_stats_id > ####
      ORDER BY monthly_bitstream_stats_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
