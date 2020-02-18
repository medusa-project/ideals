puts <<-eos

NOTE: In a typical Rails app, `db:seed` initializes the database with default
data immediately after the database has been created. But in this app, the
seed data must be added **after** content has been migrated from IDEALS.
This task (`db:seed`) is therefore not used, and `ideals:seed` must be used
instead--again, after content has been migrated.

eos
