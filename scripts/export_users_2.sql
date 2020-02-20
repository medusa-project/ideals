/* users who have submitted at least one item but are no longer assigned to any group */
copy (SELECT DISTINCT i.submitter_id, e.email
      FROM item i
               LEFT JOIN eperson e ON i.submitter_id = e.eperson_id
      WHERE submitter_id IN (
          SELECT e.eperson_id
          FROM eperson AS e
          WHERE e.password IS NOT NULL AND e.eperson_id NOT IN (
              SELECT eperson_id FROM epersongroup2eperson)))
    to STDOUT WITH DELIMITER '|' CSV HEADER;