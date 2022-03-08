##
# Abstract base class for type-specific "relations." These are inspired by, and
# conceptually the same as, {ActiveRecord::Relation}, and serve the dual
# purpose of simplifying Elasticsearch querying (which can be pretty
# complicated and awkward) by wrapping it up into an ActiveRecord-style Builder
# pattern, and marshalling the results into an object that behaves the same way
# as the one returned from ActiveRecord's querying methods.
#
# TLDR: it makes interacting with Elasticsearch more like ActiveRecord.
#
# The normal way of obtaining an instance is via {Indexed#search}. That method
# expects every searchable model to define its own subclass of this class.
# It's possible that the subclass may not even need to override anything (i.e.
# it may be empty). Otherwise, it may need to override {facet_elements}, if it
# doesn't want to use only the facetable {MetadataProfileElements} in the
# default {MetadataProfile}.
#
# For more extensive customizations, it can override {build_query}, which
# basically grants it full control over the query that gets sent to
# Elasticsearch.
#
# The Elasticsearch request and response communications are logged and are also
# available via {request_json} and {response_json}.
#
# Why this class and not
# [elasticsearch-model](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model)?
# Ultimately they are apples and oranges. This class fills a gap that that gem
# doesn't, namely hiding complicated Elasticsearch queries behind a friendly
# interface.
#
class AbstractRelation

  include Enumerable

  LOGGER = CustomLogger.new(AbstractRelation)

  DEFAULT_BUCKET_LIMIT = 10

  attr_reader :request_json, :response_json

  def initialize
    @client = ElasticsearchClient.instance

    @aggregations    = false
    @bucket_limit    = DEFAULT_BUCKET_LIMIT
    @exact_match     = false
    @filters         = [] # Array<Array<String>> Array of two-element key-value arrays (in order to support multiple identical keys)
    @limit           = ElasticsearchClient::MAX_RESULT_WINDOW
    @must_nots       = [] # Array<Array<String>> Array of two-element key-value arrays (in order to support multiple identical keys)
    @must_not_ranges = [] # Array<Hash<Symbol,String> with :field, :op, and :value keys
    @orders          = [] # Array<Hash<Symbol,String>> with :field and :direction keys
    # Hash<Symbol,String> Hash with :field and :query keys
    # Note to subclass implementations: the raw value should not be passed to
    # Elasticsearch. Use {sanitized_query} instead.
    @query           = nil
    @start           = 0

    @loaded = false

    @request_json       = {}
    @response_json      = {}
    @result_count       = 0
    @result_facets      = []
    @result_instances   = []
    @result_suggestions = []
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
      if filters.respond_to?(:keys) # check if it's a hash
        @filters = filters.keys.map{ |k| [k, filters[k]] }
      elsif filters.respond_to?(:each) # check if it's an Enumerable
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
  # @see remove_filter
  # @see must_not
  #
  def filter(field, value)
    @filters << [field, value]
    @loaded = false
    self
  end

  ##
  # @param institution [Institution]
  # @return [self]
  #
  def institution(institution)
    if institution
      filter(ElasticsearchIndex::StandardFields::INSTITUTION_KEY, institution.key)
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
  # Adds a query to search a particular field.
  #
  # @param field [String, Symbol] Field name
  # @param query [String]
  # @param exact_match [Boolean]
  # @return [self]
  #
  def query(field, query, exact_match = false)
    @query       = { field: field.to_s, query: query.to_s } if query.present?
    @exact_match = exact_match
    @loaded      = false
    self
  end

  ##
  # Adds a query to search all fields.
  #
  # @param query [String]
  # @return [self]
  #
  def query_all(query)
    query(ElasticsearchIndex::StandardFields::SEARCH_ALL, query)
    self
  end

  ##
  # @param name [String] Field name.
  # @return [self]
  # @see filter
  #
  def remove_filter(name)
    @filters.reject!{ |f| f[0] == name }
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
  # Required by the {Enumerable} contract.
  #
  def each(&block)
    to_a.each(&block)
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
  # This default implementation returns all of the facetable elements in the
  # {MetadataProfile#default default metadata profile}. Override it to return
  # others.
  #
  # @return [Enumerable<Hash<Symbol,String>>] Enumerable of Hashes with
  #                                           `:label` and `:keyword_field`
  #                                           keys.
  #
  def facet_elements
    MetadataProfile.default.elements.where(facetable: true).map do |e|
      {
          label: e.registered_element.label,
          keyword_field: e.registered_element.indexed_keyword_field
      }
    end
  end

  def load
    return if @loaded

    validate

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
          if @query.present?
            j.must do
              if !@exact_match
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
                j.simple_query_string do
                  j.query @query[:query]
                  j.default_operator 'AND'
                  j.flags 'NONE'
                  j.lenient true
                  j.fields [@query[:field]]
                end
              else
                j.term do
                  # Use the keyword field to get an exact match.
                  j.set! @query[:field] + RegisteredElement::KEYWORD_FIELD_SUFFIX,
                         sanitized_query
                end
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

  def validate
    raise "Must add an institution filter!" unless
      @filters.map{ |f| f[0] }.include?(ElasticsearchIndex::StandardFields::INSTITUTION_KEY)
  end


  private

  def get_class
    self.class.to_s.gsub("Relation", "").constantize
  end

  def get_response
    @request_json = build_query
    result = @client.query(@request_json)
    JSON.parse(result)
  end

  ##
  # @return [String] Query that is safe to pass to Elasticsearch.
  #
  def sanitized_query
    @query[:query].gsub(/[\[\]\(\)]/, "").gsub("/", " ")
  end

end
