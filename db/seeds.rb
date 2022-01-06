Institution.create!(key:     "uiuc",
                    name:    "University of Illinois at Urbana-Champaign",
                    fqdn:    "ideals.illinois.edu",
                    org_dn:  "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu",
                    default: true)

ug = UserGroup.create!(key: "sysadmin",
                       name: "System Administrators")
lg = AdGroup.create!(urn: "urn:mace:uiuc.edu:urbana:library:units:ideals:library ideals admin")
ug.ad_groups << lg
ug.save!

puts <<-eos

NOTE: In a typical Rails app, `db:seed` initializes the database with default
data immediately after the database has been created. But in this app, most of
the seed data has to be added **after** content has been migrated from IDEALS.
Remember to invoke `ideals:seed` after content has been migrated.

eos
