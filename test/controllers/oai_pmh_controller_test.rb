require "test_helper"

##
# Tests are roughly in order and labeled by section according to:
#
# http://www.openarchives.org/OAI/openarchivesprotocol.html
#
class OaiPmhControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:uiuc)
    host! @institution.fqdn
    @valid_identifier = "oai:#{@institution.fqdn}:#{items(:uiuc_item1).handle.handle}"
    setup_opensearch
    Item.reindex_all
    refresh_opensearch
  end

  test "request() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get "/oai-pmh", params: { verb: "Identify" }
    assert_response :not_found
  end

  # 2.5.1
  test "repository supports deleted records" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert_select "Identify > deletedRecord", "persistent"
  end

  # 3.1.1
  test "verb argument is required" do
    get "/oai-pmh"
    assert_select "error", "Missing verb argument."
  end

  test "verb argument must be legal" do
    get "/oai-pmh", params: { verb: "bogus" }
    assert_select "error", "Illegal verb argument."
  end

  # 3.1.1.2
  test "POST requests with an incorrect content type cause an error" do
    post "/oai-pmh", params: { verb: "Identify" },
         headers: { "Content-Type": "text/plain" }
    assert_select "error", "Content-Type of POST requests must be "\
                           "'application/x-www-form-urlencoded'"
  end

  # 3.1.1.2
  test "POST requests with the correct content type work" do
    post "/oai-pmh", params: { verb: "Identify" },
         headers: { "Content-Type": "application/x-www-form-urlencoded" }
    assert_select "Identify > deletedRecord", "persistent"
  end

  # 3.1.2.1
  test "response content type is text/xml" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert response.headers["Content-Type"].start_with?("text/xml")
  end

  # 3.2
  test "response content type is UTF-8" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert response.headers["Content-Type"].downcase.include?("charset=utf-8")
  end

  # 3.2
  test "Error responses validate against the OAI-PMH XML schema" do
    assert xsd_validate({ verb: "bogus" })
  end

  test "GetRecord responses validate against the OAI-PMH XML schema" do
    assert xsd_validate({ verb: "GetRecord", metadataPrefix: "oai_dc" })
  end

  test "Identify responses validate against the OAI-PMH XML schema" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert xsd_validate({ verb: "Identify" })
  end

  test "ListIdentifiers responses validate against the OAI-PMH XML schema" do
    assert xsd_validate({ verb: "ListIdentifiers", metadataPrefix: "oai_dc" })
  end

  test "ListMetadataFormats responses validate against the OAI-PMH XML schema" do
    assert xsd_validate({ verb: "ListMetadataFormats", metadataPrefix: "oai_dc" })
  end

  test "ListRecords responses validate against the OAI-PMH XML schema" do
    # TODO: this needs to be validated against multiple schemas
    #assert xsd_validate({ verb: "ListRecords", metadataPrefix: "oai_dc" })
  end

  test "ListSets responses validate against the OAI-PMH XML schema" do
    assert xsd_validate({ verb: "ListSets", metadataPrefix: "oai_dc" })
  end

  # 3.3.1
  test "Identify response includes the correct date granularity" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert_select "Identify > granularity", "YYYY-MM-DDThh:mm:ssZ"
  end

  # 4.1 GetRecord
  test "GetRecord returns a record when only correct arguments are passed" do
    get "/oai-pmh", params: { verb:           "GetRecord",
                              metadataPrefix: "oai_dc",
                              identifier:     @valid_identifier }
    assert_select "GetRecord > record > header > identifier", @valid_identifier
  end

  test "GetRecord returns errors when required arguments are missing" do
    get "/oai-pmh", params: { verb: "GetRecord" }
    assert_select "error", "Missing identifier argument."
    assert_select "error", "Missing metadataPrefix argument."
  end

  test "GetRecord returns errors when illegal arguments are provided" do
    get "/oai-pmh", params: { verb: "GetRecord", cats: "cats", dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  test "GetRecord returns errors when arguments are invalid" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "cats" }
    assert_select "error", "The metadata format identified by the "\
    "metadataPrefix argument is not supported by this repository."

    get "/oai-pmh", params: { verb: "GetRecord",
                              metadataPrefix: "oai_dc",
                              identifier: "cats" }
    assert_select "error", "The value of the identifier argument is unknown "\
    "or illegal in this repository."
  end

  test "GetRecord supports etdms" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "etdms" }
    assert_select "GetRecord > record > header > identifier", @valid_identifier
  end

  test "GetRecord supports native" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "native" }
    assert_select "GetRecord > record > header > identifier", @valid_identifier
  end

  test "GetRecord supports oai_dc" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "oai_dc" }
    assert_select "GetRecord > record > header > identifier", @valid_identifier
  end

  test "GetRecord supports qdc" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "qdc" }
    assert_select "GetRecord > record > header > identifier", @valid_identifier
  end

  test "GetRecord does not support an unknown format" do
    get "/oai-pmh", params: { verb: "GetRecord",
                              identifier: @valid_identifier,
                              metadataPrefix: "bogus" }
    assert_select "error", "The metadata format identified by the "\
    "metadataPrefix argument is not supported by this repository."
  end

  # 4.2 Identify
  test "Identify returns correct information" do
    get "/oai-pmh", params: { verb: "Identify" }
    assert_select "Identify > repositoryName", "#{@institution.service_name} @ #{@institution.name}"
    assert_select "Identify > baseURL", "#{@institution.scope_url}/oai-pmh"
    assert_select "Identify > protocolVersion", "2.0"
    items = Item.non_embargoed.order(created_at: :desc).limit(1)
    assert_select "Identify > earliestDatestamp", items.first.created_at.utc.iso8601
    assert_select "Identify > deletedRecord", "persistent"
    assert_select "Identify > granularity", "YYYY-MM-DDThh:mm:ssZ"
    assert_select "Identify > adminEmail", @institution.feedback_email
  end

  test "Identify returns errors when illegal arguments are provided" do
    get "/oai-pmh", params: { verb: "Identify", cats: "cats", dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  # 4.3 ListIdentifiers
  test "ListIdentifiers returns a list when correct arguments are passed and
  results are available" do
    get "/oai-pmh", params: { verb: "ListIdentifiers",
                              metadataPrefix: "oai_dc" }
    assert_select "ListIdentifiers > header > identifier",
                  @valid_identifier

    get "/oai-pmh", params: { verb: "ListIdentifiers",
                              metadataPrefix: "oai_dc",
                              from: "2012-01-01",
                              until: "2030-01-01" }
    assert_select "ListIdentifiers > header > identifier",
                  @valid_identifier
  end

  test "ListIdentifiers returns an error when correct arguments are passed and
  no results are available" do
    get "/oai-pmh", params: { verb: "ListIdentifiers",
                              metadataPrefix: "oai_dc",
                              from: "1985-01-01",
                              until: "1985-01-02" }
    assert_select "error", "No matching records."
  end

  test "ListIdentifiers returns errors when certain arguments are missing" do
    get "/oai-pmh", params: { verb: "ListIdentifiers" }
    assert_select "error", "Missing metadataPrefix argument."
  end

  test "ListIdentifiers returns errors when illegal arguments are provided" do
    get "/oai-pmh", params: { verb: "ListIdentifiers", cats: "cats", dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  test "ListIdentifiers returns errors when arguments are invalid" do
    get "/oai-pmh", params: { verb: "ListIdentifiers", metadataPrefix: "cats" }
    assert_select "error", "The metadata format identified by the "\
    "metadataPrefix argument is not supported by this repository."
  end

  test "ListIdentifiers disallows all other arguments when resumptionToken is present" do
    get "/oai-pmh", params: { verb: "ListIdentifiers",
                              resumptionToken: "offset:10",
                              set: collections(:uiuc_collection1).id }
    assert_select "error", "resumptionToken is an exclusive argument."
  end

  # 4.4 ListMetadataFormats
  test "ListMetadataFormats returns a list when no arguments are provided to
  the generic endpoint" do
    get "/oai-pmh", params: { verb: "ListMetadataFormats" }
    assert_select "ListMetadataFormats > metadataFormat > metadataPrefix",
                  "oai_dc"
    assert_select "ListMetadataFormats > metadataFormat > metadataPrefix",
                  "native"
    assert_select "ListMetadataFormats > metadataFormat > metadataPrefix",
                  "qdc"
  end

  test "ListMetadataFormats accepts an optional identifier argument" do
    get "/oai-pmh", params: { verb: "ListMetadataFormats",
                              identifier: @valid_identifier }
    assert_select "ListMetadataFormats > metadataFormat > metadataPrefix",
                  "oai_dc"
  end

  test "ListMetadataFormats returns an error when there are no metadata
  formats available for a given item" do
    pass # This should never happen, as all items will support oai_dc.
  end

  test "ListMetadataFormats returns errors when illegal arguments are
  provided" do
    get "/oai-pmh", params: { verb: "ListMetadataFormats",
                              cats: "cats",
                              dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  test "ListMetadataFormats returns errors when arguments are invalid" do
    get "/oai-pmh", params: { verb: "ListMetadataFormats", identifier: "bogus" }
    assert_select "error", "The value of the identifier argument is unknown "\
                           "or illegal in this repository."
  end

  # 4.5 ListRecords
  test "ListRecords returns a list when correct arguments are passed and
  results are available" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "oai_dc" }
    assert_select "ListRecords > record > header > identifier",
                  @valid_identifier

    get "/oai-pmh", params: { verb: "ListRecords",
                              metadataPrefix: "oai_dc",
                              from: "2012-01-01",
                              until: "2030-01-01" }
    assert_select "ListRecords > record > header > identifier",
                  @valid_identifier
  end

  test "ListRecords returns an error when correct arguments are passed and no
  results are available" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "oai_dc",
                              from: "1985-01-01", until: "1985-01-02" }
    assert_select "error", "No matching records."
  end

  test "ListRecords returns errors when certain arguments are missing" do
    get "/oai-pmh", params: { verb: "ListRecords" }
    assert_select "error", "Missing metadataPrefix argument."
  end

  test "ListRecords returns errors when illegal arguments are provided" do
    get "/oai-pmh", params: { verb: "ListRecords", cats: "cats", dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  test "ListRecords returns errors when arguments are invalid" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "cats" }
    assert_select "error", "The metadata format identified by the "\
                           "metadataPrefix argument is not supported by this "\
                           "repository."
  end

  test "ListRecords disallows all other arguments when resumptionToken is present" do
    handle = handles(:uiuc_collection1)
    get "/oai-pmh", params: { verb:            "ListRecords",
                              resumptionToken: "offset:10",
                              set:             "col_#{handle.prefix}_#{handle.suffix}" }
    assert_select "error", "resumptionToken is an exclusive argument."
  end

  test "ListRecords supports native" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "native" }
    assert_select "ListRecords > record > header > identifier",
                  @valid_identifier
  end

  test "ListRecords supports oai_dc" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "oai_dc" }
    assert_select "ListRecords > record > header > identifier",
                  @valid_identifier
  end

  test "ListRecords supports qdc" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "qdc" }
    assert_select "ListRecords > record > header > identifier",
                  @valid_identifier
  end

  test "ListRecords does not support unknown formats" do
    get "/oai-pmh", params: { verb: "ListRecords", metadataPrefix: "bogus" }
    assert_select "error", "The metadata format identified by the "\
    "metadataPrefix argument is not supported by this repository."
  end

  # 4.6 ListSets
  test "ListSets returns a list when correct arguments are passed and results
  are available" do
    handle = handles(:uiuc_collection1)
    get "/oai-pmh", params: { verb: "ListSets" }
    assert_select "ListSets > set > setSpec",
                  "col_#{handle.prefix}_#{handle.suffix}"
  end

  test "ListSets returns errors when illegal arguments are provided" do
    get "/oai-pmh", params: { verb: "ListSets", cats: "cats", dogs: "dogs" }
    assert_select "error", "Illegal argument: cats"
    assert_select "error", "Illegal argument: dogs"
  end

  test "ListSets disallows all other arguments when resumptionToken is present" do
    handle = handles(:uiuc_collection1)
    get "/oai-pmh", params: { verb:            "ListSets",
                              resumptionToken: "offset:10",
                              set:             "col_#{handle.prefix}_#{handle.suffix}" }
    assert_select "error", "resumptionToken is an exclusive argument."
  end


  private

  def xsd_validate(params_)
    get "/oai-pmh", params: params_
    doc    = Nokogiri::XML(response.body)
    xsd    = Nokogiri::XML::Schema(File.read(File.join(Rails.root, "test", "fixtures", "files", "OAI-PMH.xsd")))
    result = xsd.validate(doc)
    puts result if result.any?
    result.empty?
  end

end
