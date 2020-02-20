/* password authenticated users who are currently associated with an eperson group */
copy (SELECT e.eperson_id, e.email
      FROM eperson AS e, epersongroup2eperson AS grp2u
      WHERE e.eperson_id = grp2u.eperson_id AND e.password IS NOT NULL)
    to STDOUT WITH DELIMITER '|' CSV HEADER;