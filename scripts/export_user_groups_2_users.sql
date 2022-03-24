copy (SELECT e2e.eperson_group_id, e2e.eperson_id
      FROM epersongroup2eperson e2e
      ORDER BY e2e.eperson_group_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
