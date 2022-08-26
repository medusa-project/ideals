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
# * `dim`:    DSpace format that exposes all elements. This is a legacy format
#             carried over from DSpace, as it is used by the
#             [Search Gateway](https://digital.library.illinois.edu). Once that
#             application has been migrated to use the `native` format, it can
#             be removed.
# * `native`: Native format that exposes all elements. This is similar to `dim`
#             and will eventually replace it.
#
# # Resumption tokens
#
# Resumption tokens are ROT-18-encoded in order to make them appear opaque,
# which will hopefully discourage clients from changing them, even though if
# they do, it's not a big deal. The decoded format is:
#
# `set:string|from:date|until:date|lsv:string|metadataPrefix:string`
#
# N.B. 1: components can be in any order, but the separators (colons and bars)
# are important.
#
# N.B. 2: Elasticsearch does not cope well when using offset/limit with large
# offsets. Instead, `lsv` (last sort value) uses its `search_after` feature for
# efficient deep paging.
#
# @see http://www.openarchives.org/OAI/openarchivesprotocol.html
# @see http://www.openarchives.org/OAI/2.0/guidelines-oai-identifier.htm
#
class OaiPmhController < ApplicationController

  include OaiPmhHelper

  protect_from_forgery with: :null_session

  before_action :validate_request

  rescue_from ActionView::Template::Error, with: :rescue_template_error

  METADATA_FORMATS = [
    {
      prefix: "dim",
      uri:    "http://www.dspace.org/xmlns/dspace/dim",
      schema: "http://www.dspace.org/schema/dim.xsd"
    },
    {
      prefix: "etdms",
      uri:    "http://www.ndltd.org/standards/metadata/etdms/1.0/",
      schema: "http://www.ndltd.org/standards/metadata/etdms/1.0/etdms.xsd"
    },
    {
      prefix: "native",
      uri:    "http://www.ideals.illinois.edu/oai-pmh/native/",
      schema: "http://www.ideals.illinois.edu/native.xsd"
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
  RESUMPTION_TOKEN_TTL                 = 10.minutes

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

    @metadata_format      = get_token_metadata_prefix
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
    @sample_item        = Item.non_embargoed.
      where(stage: Item::Stages::APPROVED).
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
    @results_offset = get_token_start
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
    @results = Item.search
    # brutal hack because ItemRelation adds a default "must not" in its initializer
    @results.instance_variable_set("@must_nots", [])
    @results.aggregations(false).
      institution(Institution.find_by_key(:uiuc)).
      # Withdrawn and buried items are exposed as (what OAI-PMH calls) deleted
      # records.
      filter(Item::IndexFields::STAGE, [Item::Stages::APPROVED,
                                        Item::Stages::WITHDRAWN,
                                        Item::Stages::BURIED]).
      # Include only items that have handles. The handle is inserted into a
      # dc:identifier:uri element, without which an item would not be
      # identifiable within the oai_dc representation.
      must_exist(Item::IndexFields::HANDLE).
      # Exclude items with current all-access embargoes.
      must_not_range("#{Item::IndexFields::EMBARGOES}.#{Embargo::IndexFields::ALL_ACCESS_EXPIRES_AT}",
                     :gt,
                     Time.now.strftime("%Y-%m-%d")).
      order(Item::IndexFields::LAST_MODIFIED).
      limit(MAX_RESULT_WINDOW)

    from = get_token_from
    if from
      from_time = Time.parse(from).utc.iso8601
      @results  = @results.filter_range(Item::IndexFields::LAST_MODIFIED,
                                        :gte, from_time)
    end

    until_ = get_token_until
    if until_
      until_time = Time.parse(until_).utc.iso8601
      @results   = @results.filter_range(Item::IndexFields::LAST_MODIFIED,
                                         :lte, until_time)
    end

    set = get_token_set
    if set.present?
      # See "identifier syntaxes" in class doc
      parts = set.split("_")
      if parts.length == 3
        handle = Handle.find_by_suffix(parts[2])
        case parts[0]
        when "com"
          @results = @results.filter(Item::IndexFields::UNITS,
                                     handle.unit_id)
        when "col"
          @results = @results.filter(Item::IndexFields::COLLECTIONS,
                                     handle.collection_id)
        end
      end
    end


    @last_sort_value     = get_token_last_sort_value
    @results             = @results.search_after([@last_sort_value]) if @last_sort_value
    @total_num_results   = @results.count
    @errors << { code:        "noRecordsMatch",
                 description: "No matching records." } if @total_num_results < 1

    @resumption_token    = new_resumption_token(set:             set,
                                                from:            from,
                                                until_:          until_,
                                                last_sort_value: @results.last_sort_value,
                                                metadata_prefix: @metadata_format)
    @next_page_available = @results.last_sort_value.present?
    @expiration_date     = resumption_token_expiration_time
  end

  ##
  # @return [String, nil] "From" from the resumptionToken, if present, or else
  #                       from the `from` argument.
  #
  def get_token_from
    parse_resumption_token("from") || params[:from]
  end

  ##
  # @return [String, nil] Last sort value from the resumptionToken.
  #
  def get_token_last_sort_value
    parse_resumption_token("lsv")
  end

  ##
  # @return [String, nil] metadataPrefix from the resumptionToken, if present,
  #                       or else from the `metadataPrefix` argument.
  #
  def get_token_metadata_prefix
    parse_resumption_token("metadataPrefix") || params[:metadataPrefix]
  end

  ##
  # @return [String, nil] Set from the resumptionToken, if present, or else
  #                       from the `set` argument.
  #
  def get_token_set
    parse_resumption_token("set") || params[:set]
  end

  ##
  # @return [Integer] Start (a.k.a. offset) from the resumptionToken, or `0` if
  #                   the resumptionToken is not present.
  #
  def get_token_start
    parse_resumption_token("start")&.to_i || 0
  end

  ##
  # @return [String, nil] "Until" from the resumptionToken, if present, or else
  #                       from the `until` argument.
  #
  def get_token_until
    parse_resumption_token("until") || params[:until]
  end

  def parse_resumption_token(key)
    if params[:resumptionToken].present?
      decoded = StringUtils.rot18(params[:resumptionToken])
      decoded.split(RESUMPTION_TOKEN_COMPONENT_SEPARATOR).each do |component|
        kv = component.split(RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR)
        return kv[1..].join(":") if kv.length >= 2 && kv[0] == key
      end
    end
    nil
  end

  def rescue_template_error(error)
    message = IdealsMailer.error_body(error,
                                      url_path: request.path,
                                      user:     current_user)
    Rails.logger.error(message)
    IdealsMailer.error(message).deliver_now unless Rails.env.development?

    @error = error
    render "server_error",
           formats:  :xml,
           handlers: :builder,
           status:   :internal_server_error
  end

  def new_resumption_token(set:, from:, until_:, last_sort_value:,
                           metadata_prefix:)
    token = [
      ["set", set],
      ["from", from],
      ["until", until_],
      ["lsv", last_sort_value],
      ["metadataPrefix", metadata_prefix]
    ].select{ |a| a[1].present? }.
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
