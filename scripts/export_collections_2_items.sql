copy (SELECT c2i.item_id, c2i.collection_id, i.owning_collection
      FROM collection2item c2i
      LEFT JOIN item i ON c2i.item_id = i.item_id
      ORDER BY c2i.item_id)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
