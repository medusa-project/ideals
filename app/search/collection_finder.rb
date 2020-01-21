##
# Provides a convenient ActiveRecord-style Builder interface for Collection
# retrieval.
#
class CollectionFinder < AbstractFinder

  LOGGER = CustomLogger.new(CollectionFinder)

  def initialize
    super
    @include_unpublished = false
    @parent_collection   = nil
    @search_children     = false
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param collection [Collection]
  # @return [self]
  #
  def parent_collection(collection)
    @parent_collection = collection
    self
  end

  ##
  # @return [Relation<Collection>]
  #
  def to_a
    cols = to_id_a.map do |id|
      begin
        Collection.find(id)
      rescue ActiveRecord::RecordNotFound
        LOGGER.warn("to_a(): #{id} is missing from the database")
      end
    end
    Relation.new(cols.select(&:present?),
                 count,
                 (get_start / get_limit.to_f).floor,
                 get_limit,
                 get_start)
  end

  protected

  def get_class
    Collection
  end

  private

  def load
    return if @loaded

    @response_json = get_response

    # Assemble the response aggregations into Facets.
=begin
    @response_json['aggregations']&.each do |agg|
      facet = Facet.new
      facet.name = Collection.facet_fields.select{ |f| f[:name] == agg[0] }.
          first[:label]
      facet.field = agg[0]
      agg[1]['buckets'].each do |bucket|
        term = FacetTerm.new
        term.name = bucket['key'].to_s
        term.label = bucket['key'].to_s
        term.count = bucket['doc_count']
        term.facet = facet
        facet.terms << term
      end
      @result_facets << facet
    end
=end
    if @response_json['hits']
      @result_count = @result_count['value']
    else
      @result_count = 0
      raise IOError, "#{@response_json['error']['type']}: "\
          "#{@response_json['error']['root_cause'][0]['reason']}"
    end

    @loaded = true
  end

  ##
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
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.query_string do
                j.query sanitized_query
                j.default_field @query[:field]
                j.default_operator 'AND'
                j.lenient true
              end
            end
          end

          j.filter do
            j.term do
              j.set! Collection::IndexFields::CLASS, 'Collection'
            end

            @filters.each do |field, value|
              j.child! do
                if value.respond_to?(:each)
                  j.terms do
                    j.set! field, value
                  end
                else
                  j.term do
                    j.set! field, value
                  end
                end
              end
            end

            if @parent_collection
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::PARENT_COLLECTIONS,
                         @parent_collection.repository_id
                end
              end
            end

            unless @include_unpublished
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::PUBLICLY_ACCESSIBLE, true
                end
              end
            end
          end

          if !@search_children
            j.must_not do
              unless @search_children
                j.child! do
                  j.exists do
                    j.field Collection::IndexFields::PARENT_COLLECTIONS
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      if @aggregations
        j.aggregations do
          Collection.facet_fields.each do |facet|
            j.set! facet[:name] do
              j.terms do
                j.field facet[:name]
                j.size @bucket_limit
              end
            end
          end
        end
      end

      # Ordering
      if @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
            end
          end
        end
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

end