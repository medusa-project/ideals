# Migration

The goal with regard to migration out of DSpace is to be able to do it with
minimal downtime and without having to switch either system into a read-only
mode.

In practice, downtime may be as little as 15 minutes, but historical download
statistics and full text search will be unavailable for several days.

The migration process preserves the database IDs of the main entities
(communities, collections, and items) being migrated. The application
intercepts requests to the old entity URL paths and redirects them to their new
equivalents, so no broken links should result.

Not all DSpace data is migrated--only what is needed at UIUC Library. There is
actually quite a lot of data that does **not** get migrated as IDEALS is
**not** a feature-for-feature replacement for DSpace.

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
   DSpace's database content. This will take 8+ hours.
3. `rails ideals:seed_database` seeds the database with some additional data.
4. `rails elasticsearch:reindex[2]` indexes migrated content in Elasticsearch.
   The argument is the parallelism count, which can speed up the process, but
   can also overwhelm the Elasticsearch cluster if too large. With a safe
   parallelism of 2, this should take around 4 hours.
5. `rails dspace:bitstreams:copy[dspace_ssh_user,4]` is run. The second
   argument is the parallelism count. This will likely take several days. If
   interrupted, it will pick up where it left off when resumed.
6. Now we change the DNS to point to this app instead of DSpace. At this point,
   DSpace is no longer publicly accessible, but its database is still running,
   and this application has not yet started, so users are seeing an HTTP 503
   (Service Unavailable) message. We cannot start the application yet because
   we would expect users to immediately start submitting items, which would 
   receive auto-incrementing database primary keys that would clash with those
   created in DSpace after our initial migration. So we have to migrate those
   first:
7. `rails dspace:migrate_incremental[dbname,dbhost,dbuser,dbpass]` migrates any
   content that was added to DSpace since the previous migration. This should
   take less than a half hour.
8. Now we start the application.
9. `rails dspace:bitstreams:copy[dspace_ssh_user,4]` is run again to copy any
   files corresponding to any new bitstreams that were just incrementally
   migrated.
10. `rails elasticsearch:reindex[2]` is run again to index the content that was
    just incrementally migrated.

At this point, we are confident that all critical content from DSpace has been
migrated, so we move on to the non-critical content.

11. `rails dspace:migrate_non_critical[dbname,dbhost,dbuser,dbpass]` migrates 
    remaining relatively unimportant content from DSpace. This will take 
    several days.

DSpace can now be fully decommissioned.

12. `rails downloads:compile_monthly_counts` processes the download events
    imported in the previous step into a reporting table. This will take about
    a day.
13. `rails bitstreams:read_full_text[4]` is run. This will take several more
    days.
