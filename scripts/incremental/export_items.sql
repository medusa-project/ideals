copy (SELECT i.item_id, i.submitter_id, i.in_archive, i.withdrawn, i.discoverable
    FROM item i
    WHERE i.item_id NOT IN (####)
    ORDER BY i.item_id)
to STDOUT WITH DELIMITER '|' CSV HEADER;
