copy (SELECT collection_id, community_id as unit_id
      FROM community2collection
      ORDER BY collection_id)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
