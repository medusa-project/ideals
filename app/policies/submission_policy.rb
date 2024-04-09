# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param item [Item]
  #
  def initialize(request_context, item)
    super(request_context)
    @item = item
  end

  def complete
    update
  end

  def create
    @user && @role_limit >= Role::LOGGED_IN ? AUTHORIZED_RESULT : LOGGED_OUT_RESULT
  end

  def destroy
    update
  end

  def edit
    update
  end

  def edit_metadata
    edit
  end

  def new
    create
  end

  def update
    ItemPolicy.new(@request_context, @item).update
  end

end
