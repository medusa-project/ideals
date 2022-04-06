module Search

  include ActiveSupport::Concern

  ADVANCED_SEARCH_PARAMS = [:advisor, :advisor_type, :author, :degree_level,
                            :department, :date_deposited, :full_text,
                            :full_text_type, :title]
  SIMPLE_SEARCH_PARAMS   = [:q]
  RESULTS_PARAMS         = [:direction, :fq, :sort, :start]

  ##
  # @param relation [ItemRelation]
  #
  def process_search_input(relation)
    permitted_params = params.permit(SIMPLE_SEARCH_PARAMS + ADVANCED_SEARCH_PARAMS)
    elements         = RegisteredElement.all

    ####################### Simple Search fields ############################
    relation.query_all(permitted_params[:q]) if permitted_params[:q].present?

    ###################### Advanced Search fields ###########################
    # Title
    relation.query(elements.find{ |e| e.name == "dc:title"}.indexed_name,
                   permitted_params[:title]) if permitted_params[:title].present?
    # Author
    relation.query(elements.find{ |e| e.name == "dc:creator"}.indexed_name,
                   permitted_params[:author]) if permitted_params[:author].present?
    # Advisor
    case permitted_params[:advisor_type]
    when "advisor"
      relation.query(elements.find{ |e| e.name == "dc:contributor:advisor"}.indexed_name,
                     permitted_params[:advisor])
    when "committee_chair"
      relation.query(elements.find{ |e| e.name == "dc:contributor:committeeChair"}.indexed_name,
                     permitted_params[:advisor])
    when "committee_member"
      relation.query(elements.find{ |e| e.name == "dc:contributor:committeeMember"}.indexed_name,
                     permitted_params[:advisor])
    end
    # Degree Level
    relation.query(elements.find{ |e| e.name == "thesis:degree:level"}.indexed_name,
                   permitted_params[:degree_level]) if permitted_params[:degree_level].present?
    # Department
    relation.query(elements.find{ |e| e.name == "thesis:degree:department"}.indexed_name,
                   permitted_params[:department]) if permitted_params[:department].present?
    # Date Deposited
    relation.query(elements.find{ |e| e.name == "dc:date:submitted"}.indexed_name,
                   permitted_params[:date_deposited])if permitted_params[:date_deposited].present?
    # Full Text
    case permitted_params[:full_text_type]
    when "full_text"
      relation.query(Item::IndexFields::FULL_TEXT, permitted_params[:full_text])
    when "abstract"
      relation.query(elements.find{ |e| e.name == "dc:description:abstract"}.indexed_name,
                     permitted_params[:full_text])
    when "keywords"
      relation.query(elements.find{ |e| e.name == "dc:subject"}.indexed_name,
                     permitted_params[:full_text])
    end
  end

end