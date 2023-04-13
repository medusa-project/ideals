# frozen_string_literal: true

class WelcomeController < ApplicationController

  LOGGER = CustomLogger.new(WelcomeController)

  before_action :ensure_institution_host, only: :about
  before_action :store_location, only: :index

  ##
  # Responds to `GET /about`
  #
  def about
    @about_html = current_institution&.about_html
  end

  ##
  # Responds to `POST /contact` (XHR only)
  #
  def contact
    # These error messages are injected into the contact form alert via JS.
    if !current_user && !check_captcha # the captcha is not used if there is a logged-in user
      render plain: "Incorrect math question response.", status: :bad_request
      return
    elsif params[:comment]&.blank? # name and email are optional, but comment is required
      render plain: "Please enter a comment.", status: :bad_request
      return
    end
    feedback_email = current_institution&.feedback_email ||
      Institution.find_by_key("uiuc").feedback_email # TODO: we need a global feedback email
    begin
      IdealsMailer.contact(page_url:   params[:page_url],
                           from_name:  params[:name],
                           from_email: params[:email],
                           comment:    params[:comment],
                           to_email:   feedback_email).deliver_now
    rescue => e
      LOGGER.error("#{e}")
      render plain: "An error occurred on the server. If this error " +
                    "persists, please email us at: " + feedback_email,
             status: :internal_server_error
    else
      render plain: "OK"
    end
  end

  ##
  # Responds to `GET /`
  #
  def index
    if institution_host?
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
    @institutions     = Institution.order(:name)
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
