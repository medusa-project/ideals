copy (SELECT child_comm_id as group_id, parent_comm_id as parent_unit_id
      FROM community2community
      ORDER BY child_comm_id)
TO STDOUT
WITH DELIMITER '|' CSV HEADER;