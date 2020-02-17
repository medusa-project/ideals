copy (SELECT u.eperson_id, u.email
      FROM eperson u
      ORDER BY u.eperson_id)
    to STDOUT WITH DELIMITER '|' CSV HEADER;
