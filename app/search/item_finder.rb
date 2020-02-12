##
# Provides a convenient ActiveRecord-style Builder interface for Item retrieval.
#
class ItemFinder < AbstractFinder

  LOGGER = CustomLogger.new(ItemFinder)

  def initialize
    super
    @collection_id = nil
  end

  ##
  # @param collection [Collection,Integer] Instance or ID.
  # @return [ItemFinder] self
  #
  def collection(collection)
    @collection_id = collection.kind_of?(Collection) ?
                         collection.id : collection
    self
  end

  protected

  def get_class
    Item
  end

  def load
    return if @loaded

    @response_json = get_response

    # Assemble the response aggregations into Facets. The order of the facets
    # should be the same as the order of elements in the metadata profile.
    metadata_profile.facetable_elements.each do |profile_element|
      keyword_field = profile_element.registered_element.indexed_keyword_field
      agg = @response_json['aggregations']&.find{ |a| a[0] == keyword_field }
      if agg
        facet = Facet.new.tap do |f|
          f.name  = profile_element.label
          f.field = keyword_field
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

  def metadata_profile
    profile = nil
    if @collection_id
      profile = Collection.find(@collection_id)&.effective_metadata_profile
    end
    profile ||=  MetadataProfile.default
    profile
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
            j.bool do
              j.must do
                j.term do
                  j.set! Item::IndexFields::CLASS, 'Item'
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

                if @collection_id
                  j.child! do
                    j.term do
                      j.set! Item::IndexFields::COLLECTIONS,
                             @collection_id
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
          metadata_profile.facetable_elements.each do |profile_element|
            keyword_field = profile_element.registered_element.indexed_keyword_field
            j.set! keyword_field do
              j.terms do
                j.field keyword_field
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
=begin
        el = metadata_profile.default_sortable_element
        if el
          j.sort do
            j.set! el.indexed_sort_field do
              j.order 'asc'
              j.unmapped_type 'keyword'
            end
          end
        end
=end
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