xml.instruct!
xml.instruct! :"xml-stylesheet", type: "text/xsl", href: "/oai-pmh.xsl"

xml.tag!('OAI-PMH',
         { 'xmlns': 'http://www.openarchives.org/OAI/2.0/',
           'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
           'xsi:schemaLocation': 'http://www.openarchives.org/OAI/2.0/ '\
           'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd'
         }) do
  # 3.2 #3
  xml.tag!('responseDate', Time.now.utc.iso8601)

  # 3.2 #3
  xml.tag!('request', @request_args, oai_pmh_url)

  # 3.2 #4, 3.6
  if @errors.any?
    @errors.each do |error|
      xml.tag!('error', { 'code': error[:code] }, error[:description])
    end
  else
    xml.tag!('GetRecord') do
      xml.tag!('record') do
        deleted = [Item::Stages::WITHDRAWN, Item::Stages::BURIED].include?(@item.stage)
        status  = {}
        if deleted
          status['status'] = "deleted"
          event     = @item.events.find{ |e| e.event_type == Event::Type::DELETE }
          datestamp = event.happened_at if event
        end
        datestamp ||= @item.updated_at

        xml.tag!('header', status) do
          xml.tag!('identifier', @identifier)
          xml.tag!('datestamp', datestamp.strftime('%Y-%m-%d'))
          @item.all_collections.each do |collection|
            args = { host: @host }
            # All collections should have a handle, but for safety's sake, we
            # can fall back to using the model ID.
            if collection.handle
              args[:collection_handle_suffix] = collection.handle.suffix
            else
              args[:collection] = collection
            end
            xml.tag!('setSpec', oai_pmh_identifier(**args))
          end
          @item.all_units.each do |unit|
            args = { host: @host }
            # All units should have a handle, but for safety's sake, we can
            # fall back to using the model ID.
            if unit.handle
              args[:unit_handle_suffix] = unit.handle.suffix
            else
              args[:unit] = unit
            end
            xml.tag!('setSpec', oai_pmh_identifier(**args))
          end
        end
        unless deleted
          xml.tag!('metadata') do
            oai_pmh_metadata_for(@item, @metadata_format, xml)
          end
        end
      end
    end
  end

end
