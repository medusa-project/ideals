UserGroup.create!(key: "sysadmin",
                  name: "System Administrators")

puts <<-eos

NOTE: In a typical Rails app, `db:seed` initializes the database with default
data immediately after the database has been created. But in this app, most of
the seed data has to be added **after** content has been migrated from IDEALS.
Remember to invoke `ideals:seed` after content has been migrated.

eos
