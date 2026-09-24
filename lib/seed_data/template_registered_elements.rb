# frozen_string_literal: true

module SeedData
  class TemplateRegisteredElements

    ELEMENTS = [
      {
        name:                "dc:creator",
        label:               "Creator",
        uri:                 "http://purl.org/dc/elements/1.1/creator",
        dublin_core_mapping: "creator",
        highwire_mapping:    "citation_author",
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:description",
        label:               "Description",
        uri:                 "http://purl.org/dc/elements/1.1/description",
        dublin_core_mapping: "description",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_AREA
      },
      {
        name:                "dc:identifier",
        label:               "Identifier",
        uri:                 "http://purl.org/dc/elements/1.1/identifier",
        dublin_core_mapping: "identifier",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:language",
        label:               "Language",
        uri:                 "http://purl.org/dc/elements/1.1/language",
        dublin_core_mapping: "language",
        highwire_mapping:    "citation_language",
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:publisher",
        label:               "Publisher",
        uri:                 "http://purl.org/dc/elements/1.1/publisher",
        dublin_core_mapping: "publisher",
        highwire_mapping:    "citation_publisher",
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:rights",
        label:               "Copyright Statement",
        uri:                 "http://purl.org/dc/elements/1.1/rights",
        dublin_core_mapping: "rights",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:subject",
        label:               "Subject",
        uri:                 "http://purl.org/dc/elements/1.1/subject",
        dublin_core_mapping: "subject",
        highwire_mapping:    "citation_keywords",
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:title",
        label:               "Title",
        uri:                 "http://purl.org/dc/elements/1.1/title",
        dublin_core_mapping: "title",
        highwire_mapping:    "citation_title",
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dc:type",
        label:               "Type of Resource",
        uri:                 "http://purl.org/dc/elements/1.1/type",
        dublin_core_mapping: "type",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:abstract",
        label:               "Abstract",
        uri:                 "http://purl.org/dc/terms/abstract",
        dublin_core_mapping: "description",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_AREA
      },
      {
        name:                "dcterms:available",
        label:               "Available",
        uri:                 "http://purl.org/dc/terms/available",
        dublin_core_mapping: "date",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:dateAccepted",
        label:               "Date Accepted",
        uri:                 "http://purl.org/dc/terms/dateAccepted",
        dublin_core_mapping: "date",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:dateSubmitted",
        label:               "Date Submitted",
        uri:                 "http://purl.org/dc/terms/dateSubmitted",
        dublin_core_mapping: "date",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:identifier",
        label:               "Handle URI",
        uri:                 "http://purl.org/dc/terms/identifier",
        dublin_core_mapping: "identifier",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:isPartOf",
        label:               "Part Of",
        uri:                 "http://purl.org/dc/terms/isPartOf",
        dublin_core_mapping: "relation",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "dcterms:issued",
        label:               "Date of Publication",
        uri:                 "http://purl.org/dc/terms/issued",
        dublin_core_mapping: "date",
        highwire_mapping:    "citation_publication_date",
        input_type:          RegisteredElement::InputType::DATE
      },
      {
        name:                "dcterms:spatial",
        label:               "Geographic Coverage",
        uri:                 "http://purl.org/dc/terms/spatial",
        dublin_core_mapping: "coverage",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      },
      {
        name:                "orcid:identifier",
        label:               "ORCID Identifier",
        uri:                 nil,
        dublin_core_mapping: "identifier",
        highwire_mapping:    nil,
        input_type:          RegisteredElement::InputType::TEXT_FIELD
      }
    ].freeze

    def self.call
      new.call
    end

    def call
      ELEMENTS.each do |attrs|
        element = RegisteredElement.find_or_initialize_by(
          institution: nil,
          template:    true,
          name:        attrs[:name]
        )
        element.assign_attributes(attrs.merge(template: true, institution: nil))
        element.save!
      end
    end

  end
end