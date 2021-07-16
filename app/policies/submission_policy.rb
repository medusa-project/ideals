# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy

  attr_reader :user, :role, :item

  ##
  # @param request_context [RequestContext]
  # @param item [Item]
  #
  def initialize(request_context, item)
    @request_context = request_context
    @user            = request_context&.user
    @role            = request_context&.role_limit
    @item            = item
  end

  def agreement
    create
  end

  def complete
    update
  end

  def create
    user && role >= Role::LOGGED_IN ? AUTHORIZED_RESULT : LOGGED_OUT_RESULT
  end

  def destroy
    update
  end

  def edit
    update
  end

  def update
    ItemPolicy.new(@request_context, item).update
  end

end
