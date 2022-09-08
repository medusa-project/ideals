##
# Concern to be included by controllers that receive user input from search
# forms.
#
# See [Indexed] for an overview of how Elasticsearch interaction works.
#
module Search

  include ActiveSupport::Concern

  SIMPLE_SEARCH_PARAMS   = [:q]
  RESULTS_PARAMS         = [:direction, { fq: [] }, :sort, :start]

  def self.advanced_search_params
    [:full_text, { elements: MetadataProfile.default.elements.map(&:name) }]
  end

  ##
  # Mutates the given [ItemRelation] to reflect input from a simple or advanced
  # search form.
  #
  # @param relation [ItemRelation] The {ItemRelation#metadata_profile()
  #                                metadata profile} should already be set.
  # @return [void]
  #
  def process_search_input(relation)
    # Params from simple search will contain only `q`.
    # Advanced search params are expected to arrive in the following structure:
    # {
    #   elements: [
    #     element_name => string,
    #     element_name => string,
    #     element_name => {
    #       month: integer,
    #       day:   integer,
    #       year:  integer
    #     }
    #   ],
    #   full_text: string
    # }
    permitted_params = params.permit!

    if permitted_params[:q].present? # simple search
      relation.query_searchable_fields(permitted_params[:q])
    else # advanced search
      # (These fields generally come from ItemsHelper.advanced_search_form().)
      if permitted_params[:elements]&.respond_to?(:each)
        all_elements = RegisteredElement.all
        permitted_params[:elements].each do |e_name, term|
          term = nil if term.respond_to?(:keys) && term[:year].blank?
          if term.present?
            field = all_elements.find{ |e| e.name == e_name}&.indexed_field
            relation.multi_query(field, term) if field
          end
        end
        # Full text
        relation.multi_query(Item::IndexFields::FULL_TEXT, permitted_params[:full_text])
      end
    end
  end

end