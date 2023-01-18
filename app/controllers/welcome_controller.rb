class WelcomeController < ApplicationController

  layout -> { institution_scope? ? "application" : "global_application" }

  before_action :store_location, only: :index

  ##
  # Responds to `GET /about`
  #
  def about
    @about_html = current_institution.about_html
  end

  ##
  # Responds to `GET /`
  #
  def index
    if institution_scope?
      scoped_index
    else
      global_index
    end
  end

  def on_failed_registration
    # TODO: move this
  end


  private

  def global_index
    @institutions     = Institution.all.order(:name)
    @num_institutions = @institutions.count
    @num_items        = Rails.cache.fetch("global_num_items", expires_in: 12.hours) do
      Item.where(stage: Item::Stages::APPROVED).count
    end
    @recent_items     = Item.search.
      aggregations(false).
      order(Item::IndexFields::CREATED => :desc).
      limit(4)
    @recent_items     = policy_scope(@recent_items, policy_scope_class: ItemPolicy::Scope)
    render "index_global"
  end

  def scoped_index
    @item_count = policy_scope(Item.search.institution(current_institution).aggregations(false).limit(0),
                               policy_scope_class: ItemPolicy::Scope).count
    user = current_user
    if user
      @submissions_in_progress = user.submitted_items.
          where(stage: Item::Stages::SUBMITTING).
          order(updated_at: :desc)
    end
  rescue Errno::ECONNREFUSED
    # OpenSearch is inaccessible. This is a major problem, but not in this
    # view specifically. Other views that depend more strongly on OpenSearch
    # will not rescue this error.
  end

end
