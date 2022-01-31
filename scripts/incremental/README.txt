These scripts contain queries that are very similar to their non-incremental
counterparts, except that they exclude data that has already been imported,
generally via a "WHERE NOT IN" clause. The IDs to exclude are not known until
runtime. At runtime, each script is copied to a temporary location and the
actual IDs written into it before it is processed by psql.