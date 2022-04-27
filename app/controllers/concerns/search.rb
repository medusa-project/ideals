module Search

  include ActiveSupport::Concern

  ADVANCED_SEARCH_PARAMS = [:full_text, { elements: [] }]
  SIMPLE_SEARCH_PARAMS   = [:q]
  RESULTS_PARAMS         = [:direction, { fq: [] }, :sort, :start]

  ##
  # Mutates the given [ItemRelation] to reflect input from a simple or advanced
  # search form.
  #
  # @param relation [ItemRelation]
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

    # Simple search fields
    relation.query_all(permitted_params[:q]) if permitted_params[:q].present?

    # Advanced search fields
    # (These generally come from ItemsHelper.advanced_search_form().)
    if permitted_params[:elements]&.respond_to?(:each)
      all_elements = RegisteredElement.all
      permitted_params[:elements].each do |e_name, value|
        value = nil if value.respond_to?(:keys) && value[:year].blank?
        if value.present?
          relation.query(all_elements.find{ |e| e.name == e_name}.indexed_field,
                         value)
        end
      end
    end

    # Full text
    relation.query(Item::IndexFields::FULL_TEXT, permitted_params[:full_text])
  end

end