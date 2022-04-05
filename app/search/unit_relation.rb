class UnitRelation < AbstractRelation

  LOGGER = CustomLogger.new(UnitRelation)

  def initialize
    super
    @include_children = true
    @parent_unit      = nil
  end

  ##
  # Whether to include child units in the results.
  #
  # @param bool [Boolean]
  # @return [UnitRelation] self
  #
  def include_children(bool)
    @include_children = bool
    self
  end

  ##
  # Limits the results to children of the given parent.
  #
  # @param unit [Unit]
  # @return [UnitRelation] self
  #
  def parent_unit(unit)
    @parent_unit = unit
    self
  end


  protected

  ##
  # @return [String] JSON string.
  #
  def build_query
    Jbuilder.encode do |j|
      j.track_total_hits true
      j.query do
        j.bool do
          # Query
          if @queries.any?
            j.must do
              if @queries.length == 1 && !@exact_match
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
                j.simple_query_string do
                  j.query            @queries.first[:query]
                  j.default_operator "AND"
                  j.flags            "NONE"
                  j.lenient          true
                  j.fields           [@queries.first[:field]]
                end
              else
                @queries.each do |query|
                  j.child! do
                    j.match_phrase do
                      j.set! query[:field], sanitize(query[:query])
                    end
                  end
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

                if @parent_unit
                  j.child! do
                    j.term do
                      j.set! Unit::IndexFields::PARENT, @parent_unit.id
                    end
                  end
                end
              end
            end
          end
          j.must_not do
            j.child! do
              j.term do
                j.set! Unit::IndexFields::BURIED, true
              end
            end
            if !@include_children && !@parent_unit
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
      if @orders.respond_to?(:any?) && @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
              j.unmapped_type "keyword"
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