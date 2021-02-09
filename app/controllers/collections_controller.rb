# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :ensure_logged_in, except: [:children, :index, :show]
  before_action :set_collection, only: [:children, :show, :edit_access,
                                        :edit_collection_membership,
                                        :edit_properties,
                                        :edit_unit_membership, :update,
                                        :destroy]
  before_action :authorize_collection, only: [:show, :edit_access,
                                              :edit_collection_membership,
                                              :edit_properties,
                                              :edit_unit_membership, :update,
                                              :destroy]

  ##
  # Renders a partial for the expandable unit list used in {index}. Has the
  # same permissions as {show}.
  #
  # Responds to `GET /collections/:collection_id/children` (XHR only)
  #
  def children
    @collections = Collection.search.
        institution(current_institution).
        filter(Collection::IndexFields::PARENT, @collection.id).
        filter(Collection::IndexFields::UNIT_DEFAULT, false).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)
    render partial: "children"
  end

  ##
  # Responds to `POST /collections`.
  #
  def create
    @collection = Collection.new(collection_params)
    authorize @collection
    begin
      ActiveRecord::Base.transaction do
        # Save now in order to obtain an ID with which to associate
        # AscribedElements in the next step.
        @collection.save!
        assign_users
        build_metadata
        @collection.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@collection.title}\" created."
      render 'shared/reload'
    end
  end

  ##
  # Responds to `DELETE /collections/:id`
  #
  def destroy
    primary_unit = @collection.primary_unit
    title        = @collection.title
    begin
      ActiveRecord::Base.transaction do
        @collection.destroy!
      end
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{title}\" deleted."
    ensure
      redirect_to primary_unit
    end
  end

  ##
  # Used for editing access control.
  #
  # Responds to `GET /collections/:id/edit-membership` (XHR only)
  #
  def edit_access
    render partial: 'collections/access_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing collection membership.
  #
  # Responds to `GET /collections/:id/edit-collection-membership` (XHR only)
  #
  def edit_collection_membership
    render partial: 'collections/collection_membership_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing basic properties.
  #
  # Responds to GET `/collections/:id/edit` (XHR only)
  #
  def edit_properties
    render partial: 'collections/properties_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing unit membership.
  #
  # Responds to `GET /collections/:id/edit-unit-membership` (XHR only)
  #
  def edit_unit_membership
    render partial: 'collections/unit_membership_form',
           locals: { collection: @collection,
                     primary_unit: @collection.primary_unit }
  end

  ##
  # Responds to `GET /collections` (JSON only)
  #
  def index
    if params[:format] != "json"
      render plain: "Not Acceptable", status: :not_acceptable
      return
    end
    @start  = results_params[:start].to_i
    @window = window_size
    @collections = Collection.search.
        institution(current_institution).
        aggregations(false).
        query_all(results_params[:q]).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        start(@start).
        limit(@window)
    @count            = @collections.count
    @current_page     = @collections.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /collections/:id`
  #
  def show
    @start  = params[:start].to_i
    @window = window_size
    @items  = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::COLLECTIONS, params[:id]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = @items.page
    @permitted_params = params.permit(:q, :start)

    # Metadata tab
    @metadata_profile   = @collection.effective_metadata_profile
    @submission_profile = @collection.effective_submission_profile
    # Subcollections tab
    @subcollections = Collection.search.
        institution(current_institution).
        parent_collection(@collection).
        include_children(true).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)
    # Review Submissions tab
    @review_start  = results_params[:start].to_i
    @review_window = window_size
    @review_items  = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
        filter(Item::IndexFields::COLLECTIONS, params[:id]).
        order(Item::IndexFields::CREATED).
        start(@review_start).
        limit(@review_window)
    @review_count            = @review_items.count
    @review_current_page     = @review_items.page
    @review_permitted_params = results_params
  end

  ##
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    if params[:collection][:parent_id] &&
      !policy(@unit).change_parent?(params[:collection][:parent_id])
      raise Pundit::NotAuthorizedError,"Cannot move a collection into a "\
            "collection of which you are not an effective manager."
    end
    begin
      ActiveRecord::Base.transaction do
        assign_users
        build_metadata
        @collection.update!(collection_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@collection.title}\" updated."
      render 'shared/reload'
    end
  end

  private

  def assign_users
    # Managers
    if params[:managers].present?
      @collection.managers.destroy_all
      if params[:managers].respond_to?(:each)
        params[:managers].select(&:present?).each do |user_str|
          user = User.from_autocomplete_string(user_str)
          @collection.errors.add(:managers,
                               "includes a user that does not exist") unless user
          @collection.managing_users << user
        end
      end
    end
    # Submitters
    if params[:submitters].present?
      @collection.submitters.destroy_all
      if params[:submitters].respond_to?(:each)
        params[:submitters].select(&:present?).each do |user_str|
          user = User.from_autocomplete_string(user_str)
          @collection.errors.add(:submitters,
                               "includes a user that does not exist") unless user
          @collection.submitting_users << user
        end
      end
    end
  end

  ##
  # Builds and ascribes {AscribedElement}s to the collection based on user
  # input. This is done manually because to do it using Rails nested attributes
  # would be a PITA.
  #
  def build_metadata
    if params[:elements].present?
      config                  = ::Configuration.instance
      reg_title_element       = RegisteredElement.find_by_name(config.elements[:title])
      reg_description_element = RegisteredElement.find_by_name(config.elements[:description])

      # Remove existing title & description
      @collection.elements.where(registered_element_id: [reg_title_element.id,
                                                       reg_description_element.id]).destroy_all
      # Add title
      title = params[:elements][config.elements[:title]]
      @collection.elements.build(registered_element: reg_title_element,
                               string: title) if title.present?
      # Add description
      description = params[:elements][config.elements[:description]]
      @collection.elements.build(registered_element: reg_description_element,
                               string: description) if description.present?
    end
  end

  def set_collection
    # N.B.: the `||` supports nested routes.
    @collection = Collection.find(params[:id] || params[:collection_id])
    @breadcrumbable = @collection
  end

  def authorize_collection
    @collection ? authorize(@collection) : skip_authorization
  end

  def collection_params
    params.require(:collection).permit(:metadata_profile_id, :parent_id,
                                       :primary_unit_id,
                                       :submission_profile_id,
                                       :submissions_reviewed, :unit_default,
                                       unit_ids: [])
  end
end
