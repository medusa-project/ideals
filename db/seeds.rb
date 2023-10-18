############################# institutions #################################

Institution.create!(key:               "uiuc",
                    name:              "University of Illinois at Urbana-Champaign",
                    fqdn:              "www.ideals.illinois.edu",
                    service_name:      "IDEALS",
                    feedback_email:    "IDEALS @ Illinois <ideals@library.illinois.edu>",
                    shibboleth_org_dn: "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu")

############################## User groups #################################

ug = UserGroup.create!(key:  "sysadmin",
                       name: "System Administrators")
ug.ad_groups.build(name: "library ideals admin").save!

ug = UserGroup.create!(key:  "uiuc",
                       name: "UIUC Users")
ug.email_patterns.build(pattern: "@illinois.edu").save!

Affiliation.create!(key:  "staff",
                    name: "Staff")
Affiliation.create!(key:  "graduate",
                    name: "Graduate Student")
Affiliation.create!(key:  "masters",
                    name: "Masters Student")
Affiliation.create!(key:  "phd",
                    name: "Ph.D Student")
Affiliation.create!(key:  "undergrad",
                    name: "Undergraduate Student")

