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
    relation = Collection.search.
        query_all(results_params[:q]).
        facet_filters(results_params[:fq]).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        start(@start).
        limit(@window)
    @count            = relation.count
    @collections      = relation.to_a
    @facets           = relation.facets
    @current_page     = relation.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /collections/:id`
  #
  def show
    if @resource.items.count.positive?
      @start = params[:start].to_i
      @window = window_size
      @collections = Item.search.
          collection(params[:id]).
          start(@start).
          limit(@window)
      @count            = @collections.count
      @current_page     = @collections.page
      @permitted_params = params.permit(:q, :start)
    end
    @metadata_profile = @resource.effective_metadata_profile
    @breadcrumbable   = @resource
  end

  ##
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        build_metadata
        @resource.update!(collection_params)
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" updated."
      render 'shared/reload'
    end
  end

  private

  ##
  # Builds and ascribes {AscribedElement}s to the collection based on user
  # input. This is done manually because to do it using Rails nested attributes
  # would be a PITA.
  #
  def build_metadata
    config                  = ::Configuration.instance
    reg_title_element       = RegisteredElement.find_by_name(config.elements[:title])
    reg_description_element = RegisteredElement.find_by_name(config.elements[:description])
    if params[:elements].present?
      @resource.elements.where(registered_element_id: [reg_title_element.id,
                                                       reg_description_element.id]).destroy_all
      if params[:elements][:title].present?
        @resource.elements.build(registered_element: reg_title_element,
                                 string: params[:elements][:title])
      end
      if params[:elements][:description].present?
        @resource.elements.build(registered_element: reg_description_element,
                                 string: params[:elements][:description])
      end
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
                                       managing_user_ids: [],
                                       submitting_user_ids: [],
                                       unit_ids: [])
  end
end
