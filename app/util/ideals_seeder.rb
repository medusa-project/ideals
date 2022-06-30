##
# Seeds the database post-migration from IDEALS-DSpace.
#
class IdealsSeeder

  def seed
    update_registered_elements
    seed_metadata_profiles
    seed_submission_profiles
  end


  private

  def seed_metadata_profiles
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
                           relevance_weight:   MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT + 1,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                           position:           1,
                           relevance_weight:   MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT + 1,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:submitted"),
                           position:           2,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:advisor"),
                           position:           3,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeChair"),
                           position:           4,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeMember"),
                           position:           5,
                           visible:            true,
                           searchable:         true,
                           sortable:           true,
                           faceted:            true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                           position:           6,
                           relevance_weight:   MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT + 1,
                           visible:            true,
                           searchable:         true,
                           sortable:           false,
                           faceted:            true)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:uri"),
                           position:           7,
                           visible:            true,
                           searchable:         true,
                           sortable:           false,
                           faceted:            false)
    profile.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                           position:           8,
                           visible:            true,
                           searchable:         true,
                           sortable:           false,
                           faceted:            true)
    profile.save!
  end

  def seed_submission_profiles
    profile = SubmissionProfile.create!(name:        "Default Submission Profile",
                                        institution: Institution.find_by_key("uiuc"),
                                        default:     true)
    profile.add_default_elements
  end

  def update_registered_elements
    # See: https://uofi.app.box.com/notes/593479281190
    RegisteredElement.find_by_name("dc:contributor").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Contributor")
    RegisteredElement.find_by_name("dc:contributor:advisor").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation Director of Research or Thesis Advisor")
    RegisteredElement.find_by_name("dc:contributor:committeeChair").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation Chair")
    RegisteredElement.find_by_name("dc:contributor:committeeMember").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation Committee Member")
    RegisteredElement.find_by_name("dc:coverage:spatial").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Geographic Coverage")
    RegisteredElement.find_by_name("dc:creator").update!(
      input_type:       RegisteredElement::InputType::TEXT_FIELD,
      label:            "Creator",
      highwire_mapping: "citation_author")
    RegisteredElement.find_by_name("dc:date:issued").update!(
      input_type:       RegisteredElement::InputType::DATE,
      label:            "Date of Publication",
      highwire_mapping: "citation_publication_date")
    RegisteredElement.find_by_name("dc:date:submitted").update!(
      input_type:       RegisteredElement::InputType::DATE,
      label:            "Date Deposited")
    RegisteredElement.find_by_name("dc:description:abstract").update!(
      input_type: RegisteredElement::InputType::TEXT_AREA,
      label:      "Abstract")
    RegisteredElement.find_by_name("dc:description:sponsorship").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Sponsor/Grant No.")
    RegisteredElement.find_by_name("dc:identifier").update!(
      label:            "Identifier",
      vocabulary_key:   Vocabulary::Key::DEGREE_NAMES,
      highwire_mapping: "citation_id")
    RegisteredElement.find_by_name("dc:identifier:bibliographicCitation").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Complete Citation For This Item")
    RegisteredElement.find_by_name("dc:identifier:uri").update!(
      label: "Identifiers: URI or URL")
    RegisteredElement.find_by_name("dc:language").update!(
      label:            "Language",
      vocabulary_key:   Vocabulary::Key::COMMON_ISO_LANGUAGES,
      highwire_mapping: "citation_language")
    RegisteredElement.find_by_name("dc:publisher").update!(
      input_type:       RegisteredElement::InputType::TEXT_FIELD,
      label:            "Publisher",
      highwire_mapping: "citation_publisher")
    RegisteredElement.find_by_name("dc:relation:ispartof").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Series Name/Report No.")
    RegisteredElement.find_by_name("dc:rights").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Copyright Statement")
    RegisteredElement.find_by_name("dc:subject").update!(
      input_type:       RegisteredElement::InputType::TEXT_FIELD,
      label:            "Keyword",
      highwire_mapping: "citation_keywords")
    RegisteredElement.find_by_name("dc:title").update!(
      input_type:       RegisteredElement::InputType::TEXT_FIELD,
      label:            "Title",
      highwire_mapping: "citation_title")
    RegisteredElement.find_by_name("dc:type").update!(
      label:          "Type of Resource",
      vocabulary_key: Vocabulary::Key::COMMON_TYPES)
    RegisteredElement.find_by_name("dc:type:genre").update!(
      label:          "Genre of Resource",
      vocabulary_key: Vocabulary::Key::COMMON_GENRES)
    RegisteredElement.find_by_name("thesis:degree:department").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation/Thesis Degree Department")
    RegisteredElement.find_by_name("thesis:degree:discipline").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation/Thesis Degree Discipline")
    RegisteredElement.find_by_name("thesis:degree:grantor").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Degree Granting Institution")
    RegisteredElement.find_by_name("thesis:degree:level").update!(
      label:          "Dissertation or Thesis",
      vocabulary_key: Vocabulary::Key::DISSERTATION_THESIS)
    RegisteredElement.find_by_name("thesis:degree:name").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Degree")
    RegisteredElement.find_by_name("thesis:degree:program").update!(
      input_type: RegisteredElement::InputType::TEXT_FIELD,
      label:      "Dissertation/Thesis Degree Program")
  end

end