##
# Seeds the database post-migration from IDEALS-DSpace.
#
class IdealsSeeder

  def seed
    update_registered_element_labels
    seed_metadata_profiles
    seed_submission_profiles
  end

  private

  def seed_metadata_profiles
    # For the list of elements to include, see:
    # https://bugs.library.illinois.edu/browse/IR-65
    profile = MetadataProfile.create!(name: "Default Metadata Profile",
                                      default: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                           index: 0,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                           index: 1,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                           index: 2,
                           visible: true,
                           facetable: true,
                           searchable: true,
                           sortable: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:uri"),
                           index: 3,
                           visible: true,
                           facetable: false,
                           searchable: true,
                           sortable: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                           index: 4,
                           visible: true,
                           facetable: true,
                           searchable: true,
                           sortable: false)
    profile.save!
  end

  def seed_submission_profiles
    # This list of elements copied from:
    # https://uofi.app.box.com/notes/593479281190
    profile = SubmissionProfile.create!(name: "Default Submission Profile",
                                        default: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                           index: 0,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                           index: 1,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                           index: 2,
                           repeatable: true,
                           required: true) # TODO: checkbox list controlled by common types
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                           index: 3,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                           index: 4,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor"),
                           index: 5,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:abstract"),
                           index: 6,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:coverage:spatial"),
                           index: 7,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type:genre"),
                           index: 8,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:language"),
                           index: 9,
                           repeatable: false,
                           required: false) # TODO: dropdown controlled by ISO languages
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:bibliographicCitation"),
                           index: 10,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:publisher"),
                           index: 11,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:relation:ispartof"),
                           index: 12,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:sponsorship"),
                           index: 13,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:rights"),
                           index: 14,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier"),
                           index: 15,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:name"),
                           index: 16,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:level"),
                           index: 17,
                           repeatable: false,
                           required: false) # TODO: controlled dropdown
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeChair"),
                           index: 18,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:advisor"),
                           index: 19,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:grantor"),
                           index: 20,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:discipline"),
                           index: 21,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:department"),
                           index: 22,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:program"),
                           index: 23,
                           repeatable: false,
                           required: false)
    profile.save!
  end

  def update_registered_element_labels
    # See: https://uofi.app.box.com/notes/593479281190
    RegisteredElement.find_by_name("dc:contributor").update!(label: "Contributor")
    RegisteredElement.find_by_name("dc:contributor:advisor").update!(label: "Dissertation Director of Research or Thesis Advisor")
    RegisteredElement.find_by_name("dc:contributor:committeeChair").update!(label: "Dissertation Chair")
    RegisteredElement.find_by_name("dc:coverage:spatial").update!(label: "Geographic Coverage")
    RegisteredElement.find_by_name("dc:creator").update!(label: "Creator")
    RegisteredElement.find_by_name("dc:date:issued").update!(label: "Date of Publication")
    RegisteredElement.find_by_name("dc:description:abstract").update!(label: "Abstract")
    RegisteredElement.find_by_name("dc:description:sponsorship").update!(label: "Sponsor/Grant No.")
    RegisteredElement.find_by_name("dc:identifier").update!(label: "Identifier")
    RegisteredElement.find_by_name("dc:identifier:bibliographicCitation").update!(label: "Complete Citation For This Item")
    RegisteredElement.find_by_name("dc:identifier:uri").update!(label: "Identifiers: URI or URL")
    RegisteredElement.find_by_name("dc:language").update!(label: "Language")
    RegisteredElement.find_by_name("dc:publisher").update!(label: "Publisher")
    RegisteredElement.find_by_name("dc:relation:ispartof").update!(label: "Series Name/Report No.")
    RegisteredElement.find_by_name("dc:rights").update!(label: "Copyright Statement")
    RegisteredElement.find_by_name("dc:subject").update!(label: "Keyword")
    RegisteredElement.find_by_name("dc:title").update!(label: "Title")
    RegisteredElement.find_by_name("dc:type").update!(label: "Type of Resource")
    RegisteredElement.find_by_name("dc:type:genre").update!(label: "Genre of Resource")
    RegisteredElement.find_by_name("thesis:degree:department").update!(label: "Dissertation/Thesis Degree Department")
    RegisteredElement.find_by_name("thesis:degree:discipline").update!(label: "Dissertation/Thesis Degree Discipline")
    RegisteredElement.find_by_name("thesis:degree:grantor").update!(label: "Degree Granting Institution")
    RegisteredElement.find_by_name("thesis:degree:level").update!(label: "Dissertation or Thesis")
    RegisteredElement.find_by_name("thesis:degree:name").update!(label: "Degree")
    RegisteredElement.find_by_name("thesis:degree:program").update!(label: "Dissertation/Thesis Degree Program")
  end

end