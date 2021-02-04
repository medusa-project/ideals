##
# Seeds the database post-migration from IDEALS-DSpace.
#
class IdealsSeeder

  def seed
    seed_institutions
    update_registered_element_labels
    seed_metadata_profiles
    seed_submission_profiles
  end

  private

  def seed_institutions
    # Check first, as this might have got created in a database migration.
    unless Institution.find_by_key("uiuc")
      Institution.create!(key: "uiuc",
                          name: "University of Illinois at Urbana-Champaign")
    end
  end

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
    # This list of elements is taken from:
    # https://uofi.app.box.com/notes/593479281190
    profile = SubmissionProfile.create!(name: "Default Submission Profile",
                                        default: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                           index: 0,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                           index: 1,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                           index: 2,
                           vocabulary_key: Vocabulary::Key::COMMON_TYPES,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                           index: 3,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                           index: 4,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor"),
                           index: 5,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:abstract"),
                           index: 6,
                           input_type: SubmissionProfileElement::InputType::TEXT_AREA,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:coverage:spatial"),
                           index: 7,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type:genre"),
                           index: 8,
                           vocabulary_key: Vocabulary::Key::COMMON_GENRES,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:language"),
                           index: 9,
                           vocabulary_key: Vocabulary::Key::COMMON_ISO_LANGUAGES,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:bibliographicCitation"),
                           index: 10,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:publisher"),
                           index: 11,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:relation:ispartof"),
                           index: 12,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:sponsorship"),
                           index: 13,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:rights"),
                           index: 14,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier"),
                           index: 15,
                           vocabulary_key: Vocabulary::Key::DEGREE_NAMES,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:name"),
                           index: 16,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:level"),
                           index: 17,
                           vocabulary_key: Vocabulary::Key::DISSERTATION_THESIS,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeChair"),
                           index: 18,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:advisor"),
                           index: 19,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: true,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:grantor"),
                           index: 20,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:discipline"),
                           index: 21,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:department"),
                           index: 22,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
                           repeatable: false,
                           required: false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:program"),
                           index: 23,
                           input_type: SubmissionProfileElement::InputType::TEXT_FIELD,
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