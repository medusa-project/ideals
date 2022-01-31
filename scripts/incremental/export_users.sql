/* Users who have submitted at least one item */
copy (SELECT DISTINCT e.eperson_id, e.email
      FROM eperson e
      INNER JOIN item i ON i.submitter_id = e.eperson_id
      WHERE e.eperson_id NOT IN (####))
    to STDOUT WITH DELIMITER '|' CSV HEADER;