class WelcomeController < ApplicationController

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
    @item_count = policy_scope(Item.search.institution(current_institution).aggregations(false).limit(0),
                               policy_scope_class: ItemPolicy::Scope).count
    user = current_user
    if user
      @submissions_in_progress = user.submitted_items.
          where(stage: Item::Stages::SUBMITTING).
          order(updated_at: :desc)
    end
  rescue Errno::ECONNREFUSED
    # Elasticsearch is inaccessible. This is a major problem, but not in this
    # view specifically. Other views that depend more strongly on ES will not
    # rescue this error.
  end

  def on_failed_registration; end
end
