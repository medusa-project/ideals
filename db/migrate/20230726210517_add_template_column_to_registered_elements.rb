class AddTemplateColumnToRegisteredElements < ActiveRecord::Migration[7.0]
  def up
    add_column :registered_elements, :template, :boolean, default: false, null: false
    add_index :registered_elements, :template

    execute "INSERT INTO registered_elements(template, name, label, uri, dublin_core_mapping, highwire_mapping, input_type, created_at, updated_at)
             VALUES (true, 'dc:contributor', 'Contributor', 'http://purl.org/dc/elements/1.1/contributor', 'contributor', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dc:creator', 'Creator', 'http://purl.org/dc/elements/1.1/creator', 'creator', 'citation_author', 'text_field', NOW(), NOW()),
                    (true, 'dc:description', 'Description', 'http://purl.org/dc/elements/1.1/description', 'description', NULL, 'text_area', NOW(), NOW()),
                    (true, 'dc:identifier', 'Identifier', 'http://purl.org/dc/elements/1.1/identifier', 'identifier', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dc:language', 'Language', 'http://purl.org/dc/elements/1.1/language', 'language', 'citation_language', 'text_field', NOW(), NOW()),
                    (true, 'dc:publisher', 'Publisher', 'http://purl.org/dc/elements/1.1/publisher', 'publisher', 'citation_publisher', 'text_field', NOW(), NOW()),
                    (true, 'dc:rights', 'Copyright Statement', 'http://purl.org/dc/elements/1.1/rights', 'rights', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dc:subject', 'Subject', 'http://purl.org/dc/elements/1.1/subject', 'subject', 'citation_keywords', 'text_field', NOW(), NOW()),
                    (true, 'dc:title', 'Title', 'http://purl.org/dc/elements/1.1/title', 'title', 'citation_title', 'text_field', NOW(), NOW()),
                    (true, 'dc:type', 'Type of Resource', 'http://purl.org/dc/elements/1.1/type', 'type', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:abstract', 'Abstract', 'http://purl.org/dc/terms/abstract', 'description', NULL, 'text_area', NOW(), NOW()),
                    (true, 'dcterms:available', 'Available', 'http://purl.org/dc/terms/available', 'date', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:dateAccepted', 'Date Accepted', 'http://purl.org/dc/terms/dateAccepted', 'date', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:dateSubmitted', 'Date Submitted', 'http://purl.org/dc/terms/dateSubmitted', 'date', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:identifier', 'Handle URI', 'http://purl.org/dc/terms/identifier', 'identifier', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:isPartOf', 'Part Of', 'http://purl.org/dc/terms/isPartOf', 'relation', NULL, 'text_field', NOW(), NOW()),
                    (true, 'dcterms:issued', 'Date of Publication', 'http://purl.org/dc/terms/issued', 'date', 'citation_publication_date', 'date', NOW(), NOW()),
                    (true, 'dcterms:spatial', 'Geographic Coverage', 'http://purl.org/dc/terms/spatial', 'coverage', NULL, 'text_field', NOW(), NOW()),
                    (true, 'orcid:identifier', 'ORCID Identifier', NULL, 'identifier', NULL, 'text_field', NOW(), NOW());"
  end

  def down
    execute "DELETE FROM registered_elements WHERE template = true;"
    remove_column :registered_elements, :template
  end
end
