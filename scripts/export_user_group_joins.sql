copy (SELECT g.eperson_group_id, g2g.child_id, com.admin, col_admin.collection_id,
             col_wfs1.collection_id, col_submitter.collection_id
      FROM epersongroup g
               LEFT JOIN group2group g2g on g.eperson_group_id = g2g.parent_id
               LEFT JOIN community com on g.eperson_group_id = com.admin
               LEFT JOIN collection col_admin on g.eperson_group_id = col_admin.admin
               LEFT JOIN collection col_wfs1 on g.eperson_group_id = col_wfs1.workflow_step_1
               LEFT JOIN collection col_wfs2 on g.eperson_group_id = col_wfs2.workflow_step_2
               LEFT JOIN collection col_wfs3 on g.eperson_group_id = col_wfs3.workflow_step_3
               LEFT JOIN collection col_submitter on g.eperson_group_id = col_submitter.submitter
      WHERE col_admin.collection_id IS NOT NULL
         OR col_wfs1.collection_id IS NOT NULL
         OR col_wfs2.collection_id IS NOT NULL
         OR col_wfs3.collection_id IS NOT NULL
         OR col_submitter.collection_id IS NOT NULL
         OR com.community_id IS NOT NULL)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
