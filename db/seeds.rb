############################# institutions #################################

Institution.create!(key:     "uiuc",
                    name:    "University of Illinois at Urbana-Champaign",
                    fqdn:    "www.ideals.illinois.edu",
                    org_dn:  "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu",
                    default: true)

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

########################## Metadata profiles ################################

# Default metadata profile
profile = MetadataProfile.create!(name:        "Default Metadata Profile",
                                  institution: Institution.find_by_key("uiuc"),
                                  default:     true)
profile.add_default_elements

# ETD metadata profile
profile = MetadataProfile.create!(name:        "ETD Metadata Profile",
                                  institution: Institution.find_by_key("uiuc"),
                                  default:     false)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                       position:           0,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            false,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                       position:           1,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            true,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:submitted"),
                       position:           2,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            false,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:advisor"),
                       position:           3,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            true,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeChair"),
                       position:           4,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            true,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeMember"),
                       position:           5,
                       visible:            true,
                       searchable:         true,
                       sortable:           true,
                       faceted:            true,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                       position:           6,
                       visible:            true,
                       searchable:         true,
                       sortable:           false,
                       faceted:            true,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:uri"),
                       position:           7,
                       visible:            true,
                       searchable:         true,
                       sortable:           false,
                       faceted:            false,
                       indexed:            true)
profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                       position:           8,
                       visible:            true,
                       searchable:         true,
                       sortable:           false,
                       faceted:            true,
                       indexed:            true)
profile.save!

######################## Submission profiles ##############################

profile = SubmissionProfile.create!(name: "Default Submission Profile",
                                    institution: Institution.find_by_key("uiuc"),
                                    default: true)
profile.add_default_elements

################################# Done ######################################

puts <<-eos

Done seeding.
Remember to invoke `ideals:seed` after database content has been
migrated from DSspace!

eos
