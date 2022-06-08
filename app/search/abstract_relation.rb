##
# Abstract base class for type-specific "relations." These are inspired by, and
# conceptually the same as, [ActiveRecord::Relation], and serve the dual
# purpose of simplifying Elasticsearch querying (which can be pretty
# complicated and awkward) by wrapping it up into an ActiveRecord-style Builder
# pattern, and marshalling the results into an object that behaves the same as
# the one returned from ActiveRecord's querying methods.
#
# TLDR: it makes interacting with Elasticsearch more like ActiveRecord.
#
# See [Indexed] for an overview of how Elasticsearch interaction works in the
# application.
#
# The normal way of obtaining an instance is via {Indexed#search}. That method
# expects every searchable model to define its own subclass of this class.
# It's possible that the subclass may not even need to override anything (i.e.
# it may be empty). Otherwise, it may need to override {facet_elements}, if it
# doesn't want to use only the faceted [MetadataProfileElement]s in the
# default [MetadataProfile].
#
# For more extensive customizations, it can override {build_query}, which
# grants it full control over the query that gets sent to Elasticsearch.
#
# The request and response communications are logged and are also available via
# {request_json} and {response_json}.
#
class AbstractRelation

  include Enumerable

  LOGGER = CustomLogger.new(self.class)

  DEFAULT_BUCKET_LIMIT = 10

  attr_reader :request_json, :response_json

  def initialize
    @client = ElasticsearchClient.instance

    @aggregations     = false
    @bucket_limit     = DEFAULT_BUCKET_LIMIT
    @filter_ranges    = [] # Array<Hash<Symbol,String>> with :field, :op, and :value keys
    @filters          = [] # Array<Array<String>> Array of two-element key-value arrays (in order to support multiple identical keys)
    @limit            = ElasticsearchClient::MAX_RESULT_WINDOW
    @metadata_profile = MetadataProfile.default
    @multi_queries    = [] # Array<Hash<Symbol,String>> with :field and :term keys
    @must_nots        = [] # Array<Array<String>> Array of two-element key-value arrays (in order to support multiple identical keys)
    @must_not_ranges  = [] # Array<Hash<Symbol,String>> with :field, :op, and :value keys
    @orders           = [] # Array<Hash<Symbol,String>> with :field and :direction keys
    # Note to subclass implementations: the raw term should not be passed to
    # Elasticsearch. Use {sanitize}.
    @query            = nil # Hash<Symbol,String> Hash with :fields and :term keys
    @search_after     = nil
    @shoulds          = [] # Array<Array<String>> Array of two-element key-value arrays (in order to support multiple identical keys)
    @start            = 0

    @loaded = false

    @last_sort_value  = nil
    @request_json     = {}
    @response_json    = {}
    @result_count     = 0
    @result_facets    = []
    @result_instances = []
  end

  ###########################################################################
  # BUILDER METHODS
  # These methods initialize the query.
  ###########################################################################

  ##
  # @param boolean [Boolean] Whether to compile aggregations (for faceting) in
  #                          results. Disabling these when they are not needed
  #                          may improve performance.
  # @return [self]
  #
  def aggregations(boolean)
    @aggregations = boolean
    @loaded = false
    self
  end

  ##
  # @param limit [Integer] Maximum number of buckets that will be returned in a
  #                        facet.
  # @return [self]
  #
  def bucket_limit(limit)
    @bucket_limit = limit
    @loaded = false
    self
  end

  ##
  # @param filters [Enumerable<String>, Hash<String,Object>, String] Enumerable
  #                of strings with colon-separated fields and values; hash of
  #                fields and values; or a colon-separated field/value string.
  # @return [self]
  #
  def facet_filters(filters)
    if filters.present?
      if filters.respond_to?(:keys) # it's a hash
        @filters = filters.keys.map{ |k| [k, filters[k]] }
      elsif filters.respond_to?(:each) # it's an Enumerable
        filters.each do |filter|
          add_facet_filter_string(filter)
        end
      else
        add_facet_filter_string(filters)
      end
      @loaded = false
    end
    self
  end

  ##
  # Adds an arbitrary filter to limit results to.
  #
  # @param field [String]
  # @param value [Object] Single value or an array of "OR" values.
  # @return [self]
  # @see must_not
  #
  def filter(field, value)
    if value.respond_to?(:each)
      value.each do |v|
        @shoulds << [field, v]
      end
    else
      @filters << [field, value]
    end
    @loaded = false
    self
  end

  ##
  # @param field [String]
  # @param op [Symbol] `:gt`, `:gte`, `:lt`, or `:lte`
  # @param value [String]
  # @return [self]
  # @see must_not_range
  #
  def filter_range(field, op, value)
    @filter_ranges << { field: field, op: op, value: value }
    @loaded = false
    self
  end

  ##
  # @param institution [Institution]
  # @return [self]
  #
  def institution(institution)
    if institution
      filter(ElasticsearchIndex::StandardFields::INSTITUTION_KEY,
             institution.key)
    end
    @loaded = false
    self
  end

  ##
  # @param limit [Integer]
  # @return [self]
  #
  def limit(limit)
    @limit = limit.to_i
    @loaded = false
    self
  end

  ##
  # @param profile [MetadataProfile]
  # @return [self]
  #
  def metadata_profile(profile)
    @metadata_profile = profile
    self
  end

  ##
  # Adds a query to search for one term in one particular field.
  #
  # This is used for handling user-supplied search terms where there may be
  # multiple terms, each corresponding to one field--like in an advanced
  # search form. Unlike {query}, this method can be called multiple times to
  # add multiple queries in different fields.
  #
  # This uses an Elasticsearch `match` query which does not support Field
  # weights.
  #
  # `term` may be a string or, for date-type fields, a hash containing `:year`,
  # `:month`, and/or `:day` keys pointing to integer values.
  #
  # @param field [String, Symbol] Field name, which may have a weight suffix,
  #                               e.g. `title^5`.
  # @param term [String] Search term.
  # @return [self]
  # @see query
  # @see query_all
  # @see query_searchable_fields
  #
  def multi_query(field, term)
    return self if term.blank?
    if term.respond_to?(:keys)
      term = term.to_h.deep_symbolize_keys
    else
      term = term.to_s
    end
    @multi_queries << { field: field, term: term }
    @loaded = false
    self
  end

  ##
  # Inverse of {filter}.
  #
  # @param field [String]
  # @param value [Object] Single value or an array of "OR" values.
  # @return [self]
  # @see filter
  #
  def must_not(field, value)
    @must_nots << [field, value]
    @loaded = false
    self
  end

  ##
  # @param field [String]
  # @param op [Symbol] `:gt`, `:gte`, `:lt`, or `:lte`
  # @param value [String]
  # @return [self]
  # @see filter_range
  #
  def must_not_range(field, op, value)
    @must_not_ranges << { field: field, op: op, value: value }
    @loaded = false
    self
  end

  ##
  # @param orders [String, Enumerable<String>, Hash<String,Symbol>, Boolean]
  #               Either a field name to sort ascending, or an Enumerable of
  #               string field names and/or hashes with `field name =>
  #               direction` pairs (`:asc` or `:desc`). Supply false to
  #               disable ordering.
  # @return [self]
  #
  def order(orders)
    if orders
      @orders = [] # reset them
      if orders.respond_to?(:keys)
        field = orders.keys.first
        field = field.present? ? field : ElasticsearchIndex::StandardFields::SCORE
        @orders << { field:     field,
                     direction: orders[orders.keys.first] }
      else
        field = orders.to_s
        field = field.present? ? field : ElasticsearchIndex::StandardFields::SCORE
        @orders << { field: field, direction: :asc }
      end
      @loaded = false
    else
      @orders = false
    end
    self
  end

  ##
  # Adds a query to search for one term in one or more particular fields.
  #
  # This is generally used for handling user-supplied search terms. To do exact
  # matching, use {filter} instead. That method can be called multiple times on
  # the same instance to add multiple filters, but this one only once.
  #
  # To search across all fields, use {query_all} instead. Or, to search across
  # only searchable fields in the current {metadata_profile metadata profile},
  # use {query_searchable_fields}.
  #
  # `term` may be a string or, for date-type fields, a hash containing
  # `:year`, `:month`, and/or `:day` keys pointing to integer values.
  #
  # @param fields [String, Symbol, Enumerable<String>, Enumerable<Symbol>]
  #               Field name or names.
  # @param term [String, Hash] See above.
  # @return [self]
  # @see query_all
  # @see query_searchable_fields
  # @see multi_query
  #
  def query(fields, term)
    return self if term.blank?
    if term.respond_to?(:keys)
      term = term.to_h.deep_symbolize_keys
    else
      term = term.to_s
    end
    fields  = fields.map{ |f| weighted_field(f) }
    @query  = { fields: fields, term: term }
    @loaded = false
    self
  end

  ##
  # Adds a query to search all fields.
  #
  # Note that this does not respect
  # {MetadataProfileElement#relevance_weight element weights}, so
  # {query_searchable_fields} should usually be used instead.
  #
  # @param query [String]
  # @return [self]
  # @see query
  # @see query_searchable_fields
  # @see multi_query
  #
  def query_all(query)
    query(ElasticsearchIndex::StandardFields::SEARCH_ALL, query)
    self
  end

  ##
  # Adds a query to search for one term across all searchable fields in the
  # current [MetadataProfile metadata profile], as well as the full text field.
  # Element weights are respected.
  #
  # @param query [String, Hash] See {query}.
  # @return [self]
  # @see query
  # @see query_all
  # @see multi_query
  #
  def query_searchable_fields(query)
    fields = @metadata_profile.elements.
      select{ |e| e.searchable && e.indexed }.
      map(&:indexed_field)
    fields << ElasticsearchIndex::StandardFields::FULL_TEXT
    fields << Item::IndexFields::FILENAMES if self.kind_of?(ItemRelation)
    query(fields, query)
    self
  end

  ##
  # @param sort_value [Array] Sort value of the last result.
  # @return [self]
  #
  def search_after(sort_value)
    @search_after = sort_value
    @loaded = false
    self
  end

  ##
  # @param start [Integer]
  # @return [self]
  #
  def start(start)
    @start = start.to_i
    @loaded = false
    self
  end

  ###########################################################################
  # RESULT METHODS
  # These methods retrieve results.
  ###########################################################################

  ##
  # @return [Integer]
  #
  def count
    load
    @result_count
  end

  ##
  # Required by the [Enumerable] contract.
  #
  def each(&block)
    to_a.each(&block)
  end

  ##
  # Used to iterate over a large result set using Elasticsearch's
  # `search_after` API. This works around the
  # {ElasticsearchClient#MAX_RESULT_WINDOW} constraint inherent in using
  # {start}/{limit}.
  #
  def each_id_in_batches(&block)
    @start = nil
    @limit = nil
    order(ElasticsearchIndex::StandardFields::ID)
    to_id_a.each(&block)
    loop do
      lsv = last_sort_value
      break unless lsv
      search_after(lsv)
      to_id_a.each(&block)
    end
  end

  ##
  # @return [Enumerable<Facet>] Result facets.
  #
  def facets
    raise "Aggregations are disabled. Call `aggregations(true)` and re-run "\
        "the query." unless @aggregations
    load
    @result_facets
  end

  def last_sort_value
    load
    @last_sort_value
  end

  def method_missing(m, *args, &block)
    @result_instances.send(m, *args, &block)
  end

  ##
  # @return [Integer]
  #
  def page
    ((@start / @limit.to_f).ceil + 1 if @limit > 0) || 1
  end

  ##
  # @return [ActiveRecord::Relation<Object>]
  #
  def to_a
    ids = to_id_a.map{ |id| get_class.to_model_id(id) }
    @result_instances = get_class.
      where(id: ids).
      in_order_of(:id, ids)
    # This should improve performance for Items, as their elements relationship
    # is almost always accessed.
    if get_class == Item
      @result_instances = @result_instances.includes(:elements)
    end
    @result_instances
  end

  ##
  # @return [Enumerable<String>] Enumerable of entity IDs.
  #
  def to_id_a
    load
    @response_json['hits']['hits']
        .map{ |r| r[ElasticsearchIndex::StandardFields::ID] }
  end


  protected

  def add_facet_filter_string(str)
    parts = str.split(":")
    if parts.length == 2
      @filters << [parts[0], parts[1]]
    end
  end

  ##
  # @return [Enumerable<Hash<Symbol,String>>] Enumerable of Hashes with
  #                                           `:label` and `:keyword_field`
  #                                           keys.
  #
  def facet_elements
    @metadata_profile.elements.select(&:faceted).map do |e|
      {
        label:         e.registered_element.label,
        keyword_field: e.registered_element.indexed_keyword_field
      }
    end
  end

  def load
    return if @loaded

    @response_json = get_response

    # Assemble the response aggregations into Facets. The order of the facets
    # should be the same as the order of elements in the metadata profile.
    if @aggregations
      facet_elements.each do |element|
        agg = @response_json['aggregations']&.find{ |a| a[0] == element[:keyword_field] }
        if agg
          facet = Facet.new.tap do |f|
            f.name  = element[:label]
            f.field = element[:keyword_field]
          end
          agg[1]['buckets'].each do |bucket|
            facet.terms << FacetTerm.new.tap do |t|
              t.name  = bucket['key'].to_s
              t.label = bucket['key'].to_s
              t.count = bucket['doc_count']
              t.facet = facet
            end
          end
          @result_facets << facet
        end
      end
    end

    if @response_json['hits']
      @result_count = @response_json['hits']['total']['value']

      last_hit = @response_json['hits']['hits'].last
      @last_sort_value = last_hit ? last_hit['sort'] : nil
    else
      @result_count = 0
      raise IOError, "#{@response_json['error']['type']}: "\
          "#{@response_json['error']['reason']}"
    end

    @loaded = true
  end

  ##
  # Builds a generic query. Subclasses can override to insert their own
  # special features.
  #
  # @return [String] JSON string.
  #
  def build_query
    Jbuilder.encode do |j|
      j.track_total_hits true
      j.query do
        j.bool do
          # Query
          if @multi_queries.any?
            j.must do
              @multi_queries.each do |query|
                j.child! do
                  if query[:term].kind_of?(String)
                    # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-match-query.html
                    j.match do
                      # This query doesn't support field weights
                      j.set! query[:field], sanitize(query[:term])
                    end
                  else
                    j.range do
                      j.set! query[:field] do
                        term = query[:term]
                        date  = term[:year]
                        date += "-#{term[:month]}" if term[:month].present?
                        date += "-#{term[:day]}" if term[:day].present?
                        j.gte date
                        j.lte date
                      end
                    end
                  end
                end
              end
            end
          elsif @query
            j.must do
              if @query[:term].kind_of?(String)
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
                j.simple_query_string do
                  j.query            sanitize(@query[:term])
                  j.default_operator "AND"
                  j.flags            "NONE"
                  j.lenient          true
                  j.fields           @query[:fields]
                end
              elsif @query[:term].respond_to?(:keys) && @query[:term][:year]
                date_range_from_query(j, @query)
              end
            end
          end

          j.filter do
            j.bool do
              j.must do
                j.child! do
                  j.term do
                    j.set! ElasticsearchIndex::StandardFields::CLASS, get_class.to_s
                  end
                end
                @filters.each do |key_value|
                  unless key_value[1].nil?
                    j.child! do
                      j.term do
                        j.set! key_value[0], key_value[1]
                      end
                    end
                  end
                end
                @filter_ranges.each do |range|
                  j.child! do
                    j.range do
                      j.set! range[:field] do
                        j.set! range[:op], range[:value]
                      end
                    end
                  end
                end
              end
              if @shoulds.any?
                j.should do
                  @shoulds.each do |key_value|
                    unless key_value[1].nil?
                      j.child! do
                        j.term do
                          j.set! key_value[0], key_value[1]
                        end
                      end
                    end
                  end
                end
              end
              if @must_nots.any? || @must_not_ranges.any?
                j.must_not do
                  @must_nots.each do |key_value|
                    unless key_value[1].nil?
                      j.child! do
                        if key_value[0].respond_to?(:each)
                          j.terms do
                            j.set! key_value[0], key_value[1]
                          end
                        else
                          j.term do
                            j.set! key_value[0], key_value[1]
                          end
                        end
                      end
                    end
                  end
                  @must_not_ranges.each do |range|
                    j.child! do
                      j.range do
                        j.set! range[:field] do
                          j.set! range[:op], range[:value]
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      j.aggregations do
        if @aggregations
          facet_elements.each do |element|
            j.set! element[:keyword_field] do
              j.terms do
                j.field element[:keyword_field]
                j.size @bucket_limit
              end
            end
          end
        end
      end

      # Ordering
      # Order by explicit orders, if provided; otherwise sort by the metadata
      # profile's default order, if @orders is set to true; otherwise don't
      # sort.
      if @orders.respond_to?(:any?) && @orders.any?
        j.sort do
          @orders.each do |order|
            j.child! do
              j.set! order[:field] do
                j.order order[:direction]
                j.unmapped_type "keyword" unless order[:field] == ElasticsearchIndex::StandardFields::SCORE
              end
            end
          end
        end
      elsif @orders
      end

      # search_after
      if @search_after
        j.search_after @search_after
      end

      # Start
      if @start.present?
        j.from @start
      end

      # Limit
      if @limit.present?
        j.size @limit
      end
    end
  end


  private

  def date_range_from_query(j, query)
    j.range do
      j.set! query[:field] do
        begin_date  = query[:term][:year]
        end_date    = "#{query[:term][:year]}+1y"
        if query[:term][:month].present?
          begin_date += "-#{query[:term][:month]}"
          end_date    = "#{query[:term][:year]}-#{query[:term][:month]}+1m"
        end
        if query[:term][:day].present?
          begin_date += "-#{query[:term][:day]}"
          end_date    = "#{query[:term][:year]}-#{query[:term][:month]}-#{query[:term][:day]}+1d"
        end
        j.gte begin_date
        j.lt end_date
      end
    end
  end

  def get_class
    self.class.to_s.gsub("Relation", "").constantize
  end

  def get_response
    @request_json = build_query
    result = @client.query(@request_json)
    JSON.parse(result)
  end

  ##
  # @param query [String] Query string.
  # @return [String] String that is safe to pass to Elasticsearch.
  #
  def sanitize(query)
    query.gsub(/[\[\]\(\)]/, "").gsub("/", " ")
  end

  def weighted_field(field)
    if [ElasticsearchIndex::StandardFields::FULL_TEXT,
        Item::IndexFields::FILENAMES].include?(field)
      weight = MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT
    else
      weight = @metadata_profile.elements.
        find{ |e| e.indexed_field == field }&.
        relevance_weight
    end
    weight ||= MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT
    weight ? "#{field}^#{weight}" : field
  end

end
