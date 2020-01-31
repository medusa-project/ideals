##
# Provides a convenient ActiveRecord-style Builder interface for Collection
# retrieval.
#
class CollectionFinder < AbstractFinder

  LOGGER = CustomLogger.new(CollectionFinder)

  def initialize
    super
    @primary_unit = nil
  end

  ##
  # @param primary_unit [Unit]
  # @return [CollectionFinder] self
  #
  def primary_unit(primary_unit)
    @primary_unit = primary_unit
    self
  end

  protected

  def get_class
    Collection
  end

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
      @result_count = @response_json['hits']['total']['value']
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

            if @primary_unit
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::PRIMARY_UNIT, @primary_unit.id
                end
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