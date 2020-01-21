##
# Provides a convenient ActiveRecord-style Builder interface for Unit retrieval.
#
class UnitFinder < AbstractFinder

  LOGGER = CustomLogger.new(UnitFinder)

  def initialize
    super
    @include_children = false
  end

  ##
  # @param bool [Boolean]
  # @return [UnitFinder] self
  #
  def include_children(bool)
    @include_children = bool
    self
  end

  protected

  def get_class
    Unit
  end

  def load
    return if @loaded

    @response_json = get_response

    if @response_json['hits']
      @result_count = @response_json['hits']['total']['value']
    else
      @result_count = 0
      raise IOError, "#{@response_json['error']['type']}: "\
          "#{@response_json['error']['root_cause'][0]['reason']}"
    end

    @loaded = true
  end

  private

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
              if !@exact_match
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
                j.query_string do
                  j.query sanitized_query
                  j.default_operator 'AND'
                  j.lenient true
                  j.default_field @query[:field]
                end
              else
                j.term do
                  # Use the keyword field to get an exact match.
                  j.set! @query[:field] + EntityElement::KEYWORD_FIELD_SUFFIX,
                         sanitized_query
                end
              end
            end
          end

          j.filter do
            j.child! do
              j.term do
                j.set! Item::IndexFields::CLASS, get_class.to_s
              end
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
          end
          if !@include_children
            j.must_not do
              j.child! do
                j.exists do
                  j.field Unit::IndexFields::PARENT
                end
              end
            end
          end
        end
      end

      # Ordering
      # Order by explicit orders, if provided; otherwise sort by the metadata
      # profile's default order, if @orders is set to true; otherwise don't
      # sort.
      if @orders.respond_to?(:any?) and @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
              j.unmapped_type 'keyword'
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

end