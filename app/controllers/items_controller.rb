# frozen_string_literal: true

class ItemsController < ApplicationController

  before_action :ensure_logged_in, except: [:index, :show]
  before_action :set_item, only: [:destroy, :edit_membership, :edit_metadata,
                                  :edit_properties, :show, :update]
  before_action :authorize_item, only: [:destroy, :edit_membership,
                                        :edit_metadata, :edit_properties,
                                        :show, :update]

  ##
  # Responds to `DELETE /items/:id`
  #
  # @see cancel_submission
  #
  def destroy
    begin
      @resource.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = @resource.title.present? ?
                             "Item \"#{@resource.title}\" deleted." : "Item deleted."
    ensure
      redirect_to @resource.primary_collection
    end
  end

  ##
  # Used for editing the owning collections of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-membership` (XHR only)
  #
  def edit_membership
    render partial: "items/membership_form",
           locals: { item: @resource }
  end

  ##
  # Used for editing the metadata of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-metadata` (XHR only)
  #
  def edit_metadata
    render partial: "items/metadata_form",
           locals: { item: @resource }
  end

  ##
  # Used for editing the basic properties of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-properties` (XHR only)
  #
  def edit_properties
    render partial: "items/properties_form",
           locals: { item: @resource }
  end

  ##
  # Responds to `GET /items`
  #
  def index
    @start  = results_params[:start].to_i
    @window = window_size
    @items = Item.search.
        aggregations(true).
        query_all(results_params[:q]).
        facet_filters(results_params[:fq]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @facets           = @items.facets
    @current_page     = @items.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /items/:id`
  #
  def show
    @collections = @resource.collections.to_a
    if @resource.primary_collection
      @collections = @collections.unshift(@resource.primary_collection)
    end
    @bitstreams = @resource.bitstreams
  end

  ##
  # Responds to `PATCH/PUT /items/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        @resource.update!(item_params)
        build_metadata
        @resource.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @resource.errors.any? ? @resource : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Item \"#{@resource.title}\" updated."
      render "shared/reload"
    end
  end

  private

  def authorize_item
    @resource ? authorize(@resource) : skip_authorization
  end

  def item_params
    params.require(:item).permit(:discoverable, :primary_collection_id,
                                 :withdrawn)
  end

  def set_item
    @resource = Item.find(params[:id] || params[:item_id])
    @breadcrumbable = @resource
  end

  ##
  # Builds and ascribes {AscribedElement}s to the item based on user input.
  # This is done manually because to do it using Rails nested attributes would
  # be harder.
  #
  def build_metadata
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        @resource.elements.destroy_all
        params[:elements].each do |element|
          @resource.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                                   string:             element[:string],
                                   uri:                element[:uri])
        end
      end
    end
  end

end