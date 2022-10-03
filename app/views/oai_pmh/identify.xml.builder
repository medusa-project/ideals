xml.instruct!
xml.instruct! :"xml-stylesheet", type: "text/xsl", href: "/oai-pmh.xsl"

xml.tag!("OAI-PMH",
         { "xmlns"              => "http://www.openarchives.org/OAI/2.0/",
           "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
           "xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/ "\
                                   "http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"
         }) do
  # 3.2 #3
  xml.tag!("responseDate", Time.now.utc.iso8601)

  # 3.2 #3
  xml.tag!('request', @request_args, oai_pmh_url)

  # 3.2 #4, 3.6
  if @errors.any?
    @errors.each do |error|
      xml.tag!("error", { code: error[:code] }, error[:description])
    end
  else
    # 4.2
    xml.tag!("Identify") do
      xml.tag!("repositoryName", "IDEALS @ #{current_institution.name}")
      xml.tag!("baseURL", @base_url)
      xml.tag!("protocolVersion", "2.0")
      xml.tag!("adminEmail", current_institution.feedback_email)
      xml.tag!("earliestDatestamp", @earliest_datestamp) if @earliest_datestamp
      xml.tag!("deletedRecord", "persistent")
      xml.tag!("granularity", "YYYY-MM-DDThh:mm:ssZ")
    end
  end

end
