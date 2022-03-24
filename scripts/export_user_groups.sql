copy (SELECT g.eperson_group_id, mv.text_value
      FROM epersongroup g
               LEFT JOIN metadatavalue mv ON mv.resource_id = g.eperson_group_id
               LEFT JOIN community com on g.eperson_group_id = com.admin
               LEFT JOIN collection col_admin on g.eperson_group_id = col_admin.admin
               LEFT JOIN collection col_wfs1 on g.eperson_group_id = col_wfs1.workflow_step_1
               LEFT JOIN collection col_wfs2 on g.eperson_group_id = col_wfs2.workflow_step_2
               LEFT JOIN collection col_wfs3 on g.eperson_group_id = col_wfs3.workflow_step_3
               LEFT JOIN collection col_submitter on g.eperson_group_id = col_submitter.submitter
      WHERE mv.resource_type_id = 6
        AND col_admin.collection_id IS NULL
        AND col_wfs1.collection_id IS NULL
        AND col_wfs2.collection_id IS NULL
        AND col_wfs3.collection_id IS NULL
        AND col_submitter.collection_id IS NULL
        AND com.community_id IS NULL)
    TO STDOUT
    WITH DELIMITER '|' CSV HEADER;
