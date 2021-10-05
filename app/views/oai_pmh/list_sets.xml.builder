xml.instruct!
xml.instruct! :"xml-stylesheet", type: "text/xsl", href: "/oai-pmh.xsl"

xml.tag!('OAI-PMH',
         { 'xmlns' => 'http://www.openarchives.org/OAI/2.0/',
           'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
           'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ '\
           'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd'
         }) do
  # 3.2 #3
  xml.tag!('responseDate', Time.now.utc.iso8601)

  # 3.2 #3
  xml.tag!('request', @request_args, oai_pmh_url)

  # 3.2 #4, 3.6
  if @errors.any?
    @errors.each do |error|
      xml.tag!('error', { 'code' => error[:code] }, error[:description])
    end
  else
    # 4.6
    xml.tag!('ListSets') do
      @results.each do |row|
        xml.tag!('set') do
          if row['collection_id']
            id    = oai_pmh_identifier(collection_handle_suffix: row['handle_suffix'],
                                       host: @host)
            title = row['collection_title']
            desc  = row['collection_description']
          else
            id    = oai_pmh_identifier(unit_handle_suffix: row['handle_suffix'],
                                       host: @host)
            title = row['unit_title']
            desc  = row['unit_description']
          end
          xml.tag!('setSpec', id)
          xml.tag!('setName', title)
          if desc.present?
            xml.tag!('setDescription') do
              xml.tag!('oai_dc:dc', {
                  'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                  'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                  'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                  'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ '\
                  'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
              }) do
                xml.tag!('dc:description', desc)
              end
            end
          end
        end
      end
      xml.tag!('resumptionToken',
               { 'completeListSize' => @total_num_results,
                 'cursor' => @results_offset,
                 'expirationDate' => @expiration_date },
               @next_page_available ? @resumption_token : nil)
    end
  end

end
