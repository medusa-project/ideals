##
# Controller for the OAI-PMH endpoint.
#
# # Identifier syntaxes
#
# * Items: `oai:{host}:{handle}`
# * Collections: `col_{handle prefix}_{handle suffix}`
# * Units: `com_{handle prefix}_{handle suffix}`
#
# # Metadata formats
#
# Supported metadata formats are:
#
# * `oai_dc`: Dublin Core; exposes `dc:` elements; required by OAI-PMH
# * `qdc`:    Qualified Dublin Core; exposes `dc:` and `dcterms:` elements.
# * `dim`:    DSpace format that exposes all elements. This was carried over
#             from IDEALS-DSpace, as it is used by the
#             [Search Gateway](https://digital.library.illinois.edu) as of late
#             2021.
#
# # Resumption tokens
#
# Resumption tokens are ROT-18-encoded in order to make them appear opaque,
# which will hopefully discourage clients from changing them, even though if
# they do, it's not a big deal. The decoded format is:
#
# `set:n|from:n|until:n|start:n|metadataPrefix:n`
#
# Components can be in any order, but the separators (colons and bars) are
# important.
#
# @see http://www.openarchives.org/OAI/openarchivesprotocol.html
# @see http://www.openarchives.org/OAI/2.0/guidelines-oai-identifier.htm
#
class OaiPmhController < ApplicationController

  include OaiPmhHelper

  protect_from_forgery with: :null_session

  before_action :validate_request

  METADATA_FORMATS = [
    {
      prefix: "dim",
      uri:    "http://www.dspace.org/xmlns/dspace/dim",
      schema: "http://www.dspace.org/schema/dim.xsd"
    },
    {
      prefix: "oai_dc",
      uri:    "http://www.openarchives.org/OAI/2.0/oai_dc/",
      schema: "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
    },
    {
      prefix: "qdc",
      uri:    "http://purl.org/dc/terms/",
      schema: "http://dublincore.org/schemas/xmls/qdc/2006/01/06/dcterms.xsd"
    }
  ]
  MAX_RESULT_WINDOW                    = 100
  RESUMPTION_TOKEN_COMPONENT_SEPARATOR = "|"
  RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR = ":"
  RESUMPTION_TOKEN_TTL                 = 20.minutes

  def initialize
    super
    @errors = [] # array of hashes with `:code` and `:description` keys
  end

  ##
  # Responds to `GET/POST /oai-pmh`.
  #
  def handle
    if @errors.any? # validate_request() may have added some
      render "error", formats: :xml, handlers: :builder and return
    end

    @metadata_format      = get_metadata_prefix
    @host                 = request.host_with_port
    response.content_type = "text/xml"

    template = nil
    case params[:verb]
    when "GetRecord" # 4.1
      template = do_get_record
    when "Identify" # 4.2
      template = do_identify
    when "ListIdentifiers" # 4.3
      template = do_list_identifiers
    when "ListMetadataFormats" # 4.4
      template = do_list_metadata_formats
    when "ListRecords" # 4.5
      template = do_list_records
    when "ListSets" # 4.6
      template = do_list_sets
    when nil
      @errors << { code: "badVerb", description: "Missing verb argument." }
    else
      @errors << { code: "badVerb", description: "Illegal verb argument." }
    end

    template = "error" if @errors.any?
    render template, formats: :xml, handlers: :builder
  end

  def do_get_record
    @item = item_for_oai_pmh_identifier(params[:identifier])
    if @item
      @identifier = oai_pmh_identifier(item: @item, host: @host)
    else
      @errors << { code: "idDoesNotExist",
                   description: "The value of the identifier argument is "\
                                "unknown or illegal in this repository." }
    end
    "get_record"
  end

  def do_identify
    @sample_item        = Item.where(discoverable: true,
                                     stage: Item::Stages::APPROVED).
                            order(:updated_at).
                            limit(1).
                            first
    @earliest_datestamp = @sample_item.updated_at.utc.iso8601
    @base_url           = oai_pmh_url
    "identify"
  end

  def do_list_identifiers
    fetch_results_for_list_identifiers_or_records
    "list_identifiers"
  end

  def do_list_metadata_formats
    if params[:identifier]
      @item = item_for_oai_pmh_identifier(params[:identifier])
      @errors << { code: "idDoesNotExist",
                   description: "The value of the identifier argument is "\
                       "unknown or illegal in this repository." } unless @item
    end
    @metadata_formats = METADATA_FORMATS
    "list_metadata_formats"
  end

  def do_list_records
    fetch_results_for_list_identifiers_or_records
    "list_records"
  end

  def do_list_sets
    @results_offset = get_start
    # This endpoint considers both collections and units to be sets.
    sql = "SELECT h.suffix AS handle_suffix,
            h.collection_id AS collection_id, h.unit_id AS unit_id,
            c.title AS collection_title, c.description AS collection_description,
            u.title AS unit_title, u.short_description AS unit_description
        FROM handles h
        LEFT JOIN collections c ON h.collection_id = c.id
        LEFT JOIN units u ON h.unit_id = u.id
        WHERE h.collection_id IS NOT NULL OR h.unit_id IS NOT NULL
        ORDER BY h.suffix
        LIMIT #{MAX_RESULT_WINDOW}
        OFFSET #{@results_offset};"
    @results             = ActiveRecord::Base.connection.exec_query(sql)
    @total_num_results   = Handle.where("collection_id IS NOT NULL OR unit_id IS NOT NULL").count
    @next_page_available = (@results_offset + MAX_RESULT_WINDOW < @total_num_results)
    @expiration_date     = resumption_token_expiration_time
    "list_sets"
  end


  private

  def fetch_results_for_list_identifiers_or_records
    @results = Item.
      distinct(:id).
      joins("LEFT JOIN collection_item_memberships m ON m.item_id = items.id").
      where(discoverable: true,
            stage: [Item::Stages::APPROVED, Item::Stages::WITHDRAWN]).
      order(:updated_at)

    from = get_from
    if from
      from_time = Time.parse(from).utc.iso8601
      @results  = @results.where("items.updated_at >= ?", from_time)
    end

    until_ = get_until
    if until_
      until_time = Time.parse(until_).utc.iso8601
      @results   = @results.where("items.updated_at <= ?", until_time)
    end

    set      = get_set
    @results = @results.where("m.collection_id": set) if set

    @errors << { code: "noRecordsMatch",
                 description: "No matching records." } unless @results.any?

    @total_num_results   = @results.count
    @results_offset      = get_start
    @results             = @results.offset(@results_offset)
    @next_page_available = (@results_offset + MAX_RESULT_WINDOW < @total_num_results)
    @resumption_token    = resumption_token(set, from, until_, @results_offset,
                                            @metadata_format)
    @expiration_date     = resumption_token_expiration_time
    @results             = @results.limit(MAX_RESULT_WINDOW)
  end

  ##
  # @return [String, nil] "From" from the resumptionToken, if present, or else
  #                       from the `from` argument.
  #
  def get_from
    parse_resumption_token("from") || params[:from]
  end

  ##
  # @return [String, nil] metadataPrefix from the resumptionToken, if present,
  #                       or else from the `metadataPrefix` argument.
  #
  def get_metadata_prefix
    parse_resumption_token("metadataPrefix") || params[:metadataPrefix]
  end

  ##
  # @return [String, nil] Set from the resumptionToken, if present, or else
  #                       from the `set` argument.
  #
  def get_set
    parse_resumption_token("set") || params[:set]
  end

  ##
  # @return [Integer] Start (a.k.a. offset) from the resumptionToken, or `0` if
  #                   the resumptionToken is not present.
  #
  def get_start
    parse_resumption_token("start")&.to_i || 0
  end

  ##
  # @return [String, nil] "Until" from the resumptionToken, if present, or else
  #                       from the `until` argument.
  #
  def get_until
    parse_resumption_token("until") || params[:until]
  end

  def parse_resumption_token(key)
    if params[:resumptionToken].present?
      decoded = StringUtils.rot18(params[:resumptionToken])
      decoded.split(RESUMPTION_TOKEN_COMPONENT_SEPARATOR).each do |component|
        kv = component.split(RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR)
        return kv[1] if kv.length == 2 && kv[0] == key
      end
    end
    nil
  end

  def resumption_token(set, from, until_, current_start, metadata_prefix)
    token = [
      ["set", set],
      ["from", from],
      ["until", until_],
      ["start", current_start + MAX_RESULT_WINDOW],
      ["metadataPrefix", metadata_prefix]
    ].
      select{ |a| a[1].present? }.
      map{ |a| a.join(RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR) }.
      join(RESUMPTION_TOKEN_COMPONENT_SEPARATOR)
    StringUtils.rot18(token)
  end

  def resumption_token_expiration_time
    (Time.now + RESUMPTION_TOKEN_TTL).utc.iso8601
  end

  ##
  # @param required [Array<String>]
  # @param allowed [Array<String>]
  #
  def validate_arguments(required, allowed)
    params_hash = params.to_unsafe_hash

    # Ignore these
    ignore    = %w(action controller verb)
    allowed  -= ignore
    required -= ignore

    # Check that resumptionToken is an exclusive argument.
    if params_hash.keys.include?("resumptionToken") &&
      (params_hash.keys - ignore).length > 1
      @errors << { code: "badArgument",
                   description: "resumptionToken is an exclusive argument." }
    end

    # Check that all required args are present in the params hash.
    required.each do |arg|
      if params[arg].blank?
        # Make an exception for metadataPrefix, which is permitted to be
        # blank when resumptionToken is present.
        if arg == "metadataPrefix" &&
          params_hash.keys.include?("resumptionToken") &&
          required.include?("metadataPrefix")
          # ok
        else
          @errors << { code: "badArgument",
                       description: "Missing #{arg} argument." }
        end
      end
    end

    # Check that the params hash contains only allowed keys.
    (params_hash.keys - ignore).each do |key|
      unless allowed.include?(key)
        @errors << { code: "badArgument",
                     description: "Illegal argument: #{key}" }
      end
    end
  end

  def validate_request
    # POST requests must have a Content-Type of
    # application/x-www-form-urlencoded (3.1.1.2)
    if request.method == "POST" &&
      request.content_type != "application/x-www-form-urlencoded"
      @errors << {
        code: "badArgument",
        description: "Content-Type of POST requests must be "\
          "'application/x-www-form-urlencoded'"
      }
    end

    # Verb-specific argument validation
    required_args = allowed_args = nil
    case params[:verb]
    when "GetRecord" # 4.1
      required_args = allowed_args = %w(identifier metadataPrefix)
    when "Identify" # 4.2
      allowed_args = required_args = %w()
    when "ListIdentifiers" # 4.3
      allowed_args  = %w(from metadataPrefix resumptionToken set until)
      required_args = %w(metadataPrefix)
    when "ListMetadataFormats" # 4.4
      allowed_args  = %w(identifier)
      required_args = %w()
    when "ListRecords" # 4.5
      allowed_args  = %w(from metadataPrefix set resumptionToken until)
      required_args = %w(metadataPrefix)
    when "ListSets" # 4.6
      allowed_args  = %w(resumptionToken)
      required_args = %w()
    end
    if required_args && allowed_args
      validate_arguments(required_args, allowed_args)
    end

    # metadataPrefix validation
    if params[:metadataPrefix].present?
      valid = METADATA_FORMATS.map{ |f| f[:prefix] }.include?(params[:metadataPrefix])
      unless valid
        @errors << { code: "cannotDisseminateFormat",
                     description: "The metadata format identified by the "\
                     "metadataPrefix argument is not supported by this "\
                     "repository." }
      end
    end

    @request_args = params.except(:controller, :action).to_unsafe_hash
  end

end