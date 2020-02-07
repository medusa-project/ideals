copy (SELECT c.collection_id
    FROM collection c)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;
