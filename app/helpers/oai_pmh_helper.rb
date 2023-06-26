module OaiPmhHelper

  ##
  # @param identifier [String]
  # @return [Item]
  #
  def item_for_oai_pmh_identifier(identifier)
    matches = identifier.match(/oai:[\w.-]+(:\d+)?:(\d+)\/(\d+)/)
    if matches && matches.length >= 4
      handle = Handle.find_by_suffix(matches[3])
      return handle.item if handle&.item&.all_access_embargoes&.empty?
    end
    nil
  end

  ##
  # Obtains an OAI-PMH identifier for an [Item], [Collection], or [Unit].
  #
  # @param item [Item]
  # @param collection [Collection] Used if `collection_handle_suffix` is not
  #        provided.
  # @param collection_handle_suffix [String] Used preferentially over
  #        `collection`.
  # @param unit [Unit] Used if `unit_handle_suffix` is not provided.
  # @param unit_handle_suffix [String] Used preferentially over `unit`.
  # @param host [String]
  # @return [String]
  #
  def oai_pmh_identifier(item:                     nil,
                         collection:               nil,
                         collection_handle_suffix: nil,
                         unit:                     nil,
                         unit_handle_suffix:       nil,
                         host:)
    # see section 2.4: http://www.openarchives.org/OAI/openarchivesprotocol.html
    # These formats match the ones used by DSpace.
    if item
      return "oai:#{host}:#{item.handle}"
    elsif collection_handle_suffix
      return "col_#{Handle.prefix}_#{collection_handle_suffix}"
    elsif unit_handle_suffix
      return "com_#{Handle.prefix}_#{unit_handle_suffix}"
    elsif collection
      return "col_#{collection.id}"
    elsif unit
      return "com_#{unit.id}"
    end
    raise ArgumentError, "Unsupported arguments"
  end

  def oai_pmh_metadata_for(item, format, xml)
    case format
    when "dim"
      oai_pmh_dim_metadata_for(item, xml)
    when "etdms"
      oai_pmh_etdms_metadata_for(item, xml)
    when "native"
      oai_pmh_native_metadata_for(item, xml)
    when "oai_dc"
      oai_pmh_dc_metadata_for(item, xml)
    when "qdc"
      oai_pmh_qdc_metadata_for(item, xml)
    else
      raise ArgumentError, "Unsupported metadata format"
    end
  end


  private

  def oai_pmh_dc_metadata_for(item, xml)
    xml.tag!("oai_dc:dc", {
      "xmlns:oai_dc"       => "http://www.openarchives.org/OAI/2.0/oai_dc/",
      "xmlns:dc"           => "http://purl.org/dc/elements/1.1/",
      "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/oai_dc/ "\
                              "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
    }) do
      item.elements.each do |ae|
        value  = ae.string.strip
        next if value.blank?
        name   = nil
        # If the element has a valid DC mapping, use that.
        dc_map = ae.registered_element.dublin_core_mapping
        if dc_map.present?
          if dc_map.start_with?("dc:")
            name = dc_map
          elsif !dc_map.include?(":")
            name = "dc:#{dc_map}"
          end
        end
        # Otherwise, if the element itself is a DC element, use its native name.
        if ae.name.start_with?("dc:")
          parts = ae.name.split(":")
          if parts.length > 2
            name = parts[0..parts.length - 2].join(":")
          else
            name = ae.name
          end
        end
        xml.tag!(name, value) if name
      end
    end
  end

  def oai_pmh_dim_metadata_for(item, xml)
    xml.tag!("dim:dim", {
      "xmlns:dim"          => "http://www.dspace.org/xmlns/dspace/dim",
      "xsi:schemaLocation" => "http://www.dspace.org/xmlns/dspace/dim "\
                              "http://www.dspace.org/schema/dim.xsd" }) do
      item.elements.each do |ae|
        parts             = ae.name.split(":")
        attrs             = { mdschema: parts[0], element: parts[1] }
        attrs[:qualifier] = parts[2] if parts[2]
        xml.tag!("dim:field", attrs, ae.string)
      end
    end
  end

  def oai_pmh_etdms_metadata_for(item, xml)
    xml.tag!("thesis", {
      "xmlns"          => "http://www.ndltd.org/standards/metadata/etdms/1.0/",
      "xsi:schemaLocation" => "http://www.ndltd.org/standards/metadata/etdms/1.0/  "\
                              "http://www.ndltd.org/standards/metadata/etdms/1-0/etdms.xsd" }) do
      item.elements.each do |ae|
        parts = ae.name.split(":")
        if parts.length == 1
          name = parts[0]
        elsif parts.length > 1
          name = parts[1]
        else
          next
        end
        xml.tag!(name, ae.string)
      end
    end
  end

  def oai_pmh_native_metadata_for(item, xml)
    xml.tag!("resource", {
      "xmlns"          => "http://www.ideals.illinois.edu/oai-pmh/native/",
      "xsi:schemaLocation" => "http://www.ideals.illinois.edu/oai-pmh/native/ "\
                              "http://www.ideals.illinois.edu/native.xsd" }) do
      item.elements.each do |ae|
        parts             = ae.name.split(":")
        attrs             = { schema: parts[0], element: parts[1] }
        attrs[:qualifier] = parts[2] if parts[2]
        xml.tag!("field", attrs, ae.string)
      end
    end
  end

  def oai_pmh_qdc_metadata_for(item, xml)
    xml.tag!("qdc:qualifieddc", {
      "xmlns:dc"           => "http://purl.org/dc/elements/1.1/",
      "xmlns:dcterms"      => "http://purl.org/dc/terms/",
      "xmlns:qdc"          => "http://dspace.org/qualifieddc/",
      "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => "http://purl.org/dc/elements/1.1/ "\
                              "http://purl.org/dc/terms/ "\
                              "http://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd" }) do
      item.elements.each do |ae|
        name = ae.name
        # truncate qualifiers, e.g. dc:format:mimetype -> dc:format
        if name.start_with?("dc:") || name.start_with?("dcterms:")
          parts = name.split(":")
          if parts.length > 2
            name = parts[0..parts.length - 2].join(":")
          end
        end
        xml.tag!(name, ae.string)
      end
    end
  end

end