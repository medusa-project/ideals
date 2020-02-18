class IdealsSeeder

  def seed
    # See: https://bugs.library.illinois.edu/browse/IR-65
    profile = MetadataProfile.create!(name: "Default Profile",
                                      default: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                           index: 0,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true,
                           repeatable: false,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                           index: 1,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                           index: 2,
                           visible: true,
                           facetable: true,
                           searchable: true,
                           sortable: false,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:uri"),
                           index: 3,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                           index: 4,
                           visible: true,
                           facetable: true,
                           searchable: true,
                           sortable: false,
                           repeatable: false,
                           required: false)
    profile.save!
  end

end