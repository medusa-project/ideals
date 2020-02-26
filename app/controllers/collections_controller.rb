# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :ensure_logged_in, except: [:index, :show]
  before_action :set_collection, only: [:show, :edit_access, :edit_membership,
                                        :edit_properties, :update, :destroy]
  before_action :authorize_collection, only: [:show, :edit_access,
                                              :edit_membership,
                                              :edit_properties, :update,
                                              :destroy]

  ##
  # Responds to `POST /collections`.
  #
  def create
    begin
      @resource = Collection.new(collection_params)
      authorize @resource
      ActiveRecord::Base.transaction do
        # Save now in order to obtain an ID with which to associate
        # AscribedElements in the next step.
        @resource.save!
        assign_users
        build_metadata
        @resource.save!
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" created."
      render 'shared/reload'
    end
  end

  ##
  # Responds to `DELETE /collections/:id`
  #
  def destroy
    primary_unit = @resource.primary_unit
    begin
      ActiveRecord::Base.transaction do
        @resource.destroy!
      end
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" deleted."
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
           locals: { collection: @resource }
  end

  ##
  # Used for editing unit membership.
  #
  # Responds to `GET /collections/:id/edit-membership` (XHR only)
  #
  def edit_membership
    render partial: 'collections/membership_form',
           locals: { collection: @resource,
                     primary_unit: @resource.primary_unit }
  end

  ##
  # Used for editing basic properties.
  #
  # Responds to GET `/collections/:id/edit` (XHR only)
  #
  def edit_properties
    render partial: 'collections/properties_form',
           locals: { collection: @resource }
  end

  ##
  # Responds to `GET /collections`
  #
  def index
    @start  = results_params[:start].to_i
    @window = window_size
    @collections = Collection.search.
        aggregations(true).
        query_all(results_params[:q]).
        facet_filters(results_params[:fq]).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        start(@start).
        limit(@window)
    @count            = @collections.count
    @facets           = @collections.facets
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
        filter(Item::IndexFields::COLLECTIONS, params[:id]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @count              = @items.count
    @current_page       = @items.page
    @permitted_params   = params.permit(:q, :start)

    @metadata_profile   = @resource.effective_metadata_profile
    @submission_profile = @resource.effective_submission_profile
    @breadcrumbable     = @resource
  end

  ##
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        assign_users
        build_metadata
        @resource.update!(collection_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @resource.errors.any? ? @resource : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" updated."
      render 'shared/reload'
    end
  end

  private

  def assign_users
    # Managers
    @resource.managers.destroy_all
    if params[:managers].respond_to?(:each)
      params[:managers].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @resource.errors.add(:managers,
                             "includes a user that does not exist") unless user
        @resource.managing_users << user
      end
    end
    # Submitters
    @resource.submitters.destroy_all
    if params[:submitters].respond_to?(:each)
      params[:submitters].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @resource.errors.add(:submitters,
                             "includes a user that does not exist") unless user
        @resource.submitting_users << user
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
      @resource.elements.where(registered_element_id: [reg_title_element.id,
                                                       reg_description_element.id]).destroy_all
      # Add title
      title = params[:elements][config.elements[:title]]
      @resource.elements.build(registered_element: reg_title_element,
                               string: title) if title.present?
      # Add description
      description = params[:elements][config.elements[:description]]
      @resource.elements.build(registered_element: reg_description_element,
                               string: description) if description.present?
    end
  end

  def set_collection
    # N.B.: the `||` supports nested routes.
    @resource = Collection.find(params[:id] || params[:collection_id])
    @breadcrumbable = @resource
  end

  def authorize_collection
    @resource ? authorize(@resource) : skip_authorization
  end

  def collection_params
    params.require(:collection).permit(:metadata_profile_id,
                                       :primary_unit_id,
                                       :submission_profile_id,
                                       unit_ids: [])
  end
end
