# frozen_string_literal: true

class WelcomeController < ApplicationController

  ##
  # Responds to `GET /`
  #
  def index
    @item_count = policy_scope(Item.search.aggregations(false).limit(0),
                               policy_scope_class: ItemPolicy::Scope).count
    user = current_user
    if user
      @submissions_in_progress = user.submitted_items.
          where(submitting: true).
          order(updated_at: :desc)
    end
  rescue Errno::ECONNREFUSED
    # Elasticsearch is inaccessible. This is a major problem, but not in this
    # view specifically. Other views that depend more strongly on ES will not
    # rescue this error.
  end

  def login_choice; end

  def on_failed_registration; end
end
