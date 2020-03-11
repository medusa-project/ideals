# frozen_string_literal: true

class WelcomeController < ApplicationController
  helper_method :current_user, :logged_in?

  def index
    @item_count = policy_scope(Item.search.aggregations(false).limit(0),
                               policy_scope_class: ItemPolicy::Scope).count
    @user = current_user
    @submissions_in_progress = @user.submitted_items.
        where(submitting: true).
        order(updated_at: :desc) if @user
  end

  def login_choice; end

  def on_failed_registration; end
end
