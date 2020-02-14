class CollectionRelation < AbstractRelation

  LOGGER = CustomLogger.new(CollectionRelation)

  def initialize
    super
    @primary_unit = nil
  end

  ##
  # @param primary_unit [Unit]
  # @return [CollectionRelation] self
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

    # Assemble the response aggregations into Facets. The order of the facets
    # should be the same as the order of elements in the metadata profile.
    facet_elements.each do |element|
      field = element[:field]
      agg = @response_json['aggregations']&.find{ |a| a[0] == field }
      if agg
        facet = Facet.new.tap do |f|
          f.name  = element[:label]
          f.field = field
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
  # @return [Enumerable<Hash>] Enumerable of hashes with `label` and `field`
  #                            keys.
  #
  def facet_elements
    # Ideally we would just return the result of facetable_elements() from the
    # metadata profile. But we want to include a unit facet, for which there is
    # no corresponding MetadataProfileElement. So instead, we build and use an
    # array of pseudo-elements.
    elements = [
        {
            label: "Academic Unit",
            field: "#{Collection::IndexFields::UNIT_TITLES}.keyword"
        }
    ]
    elements += metadata_profile.facetable_elements.map do |e|
      {
          label: e.label,
          field: e.registered_element.indexed_keyword_field
      }
    end
    elements
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
        end
      end

      # Aggregations
      j.aggregations do
        if @aggregations
          facet_elements.each do |element|
            j.set! element[:field] do
              j.terms do
                j.field element[:field]
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