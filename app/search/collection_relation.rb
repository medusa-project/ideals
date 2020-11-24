class CollectionRelation < AbstractRelation

  def initialize
    super
    @include_children  = true
    @parent_collection = nil
  end

  ##
  # Whether to include child collections in the results.
  #
  # @param bool [Boolean]
  # @return [CollectionRelation] self
  #
  def include_children(bool)
    @include_children = bool
    self
  end

  ##
  # Limits the results to children of the given parent.
  #
  # @param collection [Collection]
  # @return [CollectionRelation] self
  #
  def parent_collection(collection)
    @parent_collection = collection
    self
  end

  ##
  # Limits the results to children of the given unit.
  #
  # @param unit [Unit]
  # @return [CollectionRelation] self
  #
  def primary_unit(unit)
    @primary_unit = unit
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
          if @query.present?
            j.must do
              if !@exact_match
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
                j.simple_query_string do
                  j.query sanitized_query
                  j.default_operator 'AND'
                  j.lenient true
                  j.fields [@query[:field]]
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

                if @parent_collection
                  j.child! do
                    j.term do
                      j.set! Collection::IndexFields::PARENT, @parent_collection.id
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
          if !@include_children && !@parent_collection
            j.must_not do
              j.child! do
                j.exists do
                  j.field Collection::IndexFields::PARENT
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

  def facet_elements
    elements = [
        {
            label: "Academic Unit",
            keyword_field: "#{Collection::IndexFields::UNIT_TITLES}.keyword"
        }
    ]
    elements += MetadataProfile.default.facetable_elements.map do |e|
      {
          label: e.label,
          keyword_field: e.registered_element.indexed_keyword_field
      }
    end
    elements
  end

end