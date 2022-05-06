# Migration

The goal with regard to migration out of DSpace is to be able to do it with
minimal downtime and without having to switch either system--the production
DSpace or the production this-app instance--into a read-only mode.

In practice, downtime should not be necessary, but some recently created items
on the DSpace side may be "404" for a time in the new application. Also,
historical download statistics and full text search will not be available for
several days.

Not all DSpace data is migrated--only what is needed at UIUC Library.

## Prerequisites

1. A fully functional but not yet publicly accessible production environment;
   see `README.md`.
2. The user under which the new app is running must be present in the DSpace
   user's `~/.ssh/authorized_keys` file for passwordless SSH login.
3. Take note of the following:
    1. The DSpace user's username
    2. The DSpace hostname
    3. The DSpace database's name, hostname, username, and password

## The process

The process begins with DSpace still running in production and a production
instance of this application waiting in the wings but not yet publicly
accessible.

Time estimates are based on the size of the UIUC Library's DSpace instance
(~110,000 items).

1. `rails db:prepare` creates and seeds the database.
2. `rails dspace:migrate_critical[dbname,dbhost,dbuser,dbpass]` migrates
   DSpace's database content. This may take several hours or days to complete.
3. `rails ideals:seed_database` seeds the database with some additional data.
4. `rails elasticsearch:reindex[2]` indexes migrated content in Elasticsearch.
   The argument is the parallelism count, which can speed up the process, but
   can also overwhelm the Elasticsearch cluster if too large.
5. `rails dspace:bitstreams:copy[dspace_ssh_user,4]` is run. The second
   argument is the parallelism count. This will likely take several days.

Now we change the DNS to point to this app instead of DSpace. DSpace is no
longer publicly accessible, but its database is still running.

6. `rails dspace:migrate_incremental[dbname,dbhost,dbuser,dbpass]` migrates any
   content that was added to DSpace since the previous migration.
7. `rails elasticsearch:reindex[2]` is run again to index the content that was
   just incrementally migrated.
8. `rails dspace:bitstreams:copy[dspace_ssh_user,4]` is run again to copy any
   files corresponding to any new bitstreams that were just incrementally
   migrated.

At this point, we are confident that all critical content from DSpace has been
migrated.

9. `rails dspace:migrate_non_critical[dbname,dbhost,dbuser,dbpass]` migrates 
   remaining relatively unimportant content from DSpace. This will take several
   days.

DSpace can now be fully decommissioned.

10. `rails bitstreams:read_full_text[4]` is run. This will take several days.
