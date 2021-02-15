# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy

  attr_reader :user, :role, :item

  ##
  # @param request_context [RequestContext]
  # @param item [Item]
  #
  def initialize(request_context, item)
    @user = request_context&.user
    @role = request_context&.role_limit
    @item = item
  end

  def agreement?
    create?
  end

  def complete?
    update?
  end

  def create?
    user && role >= Role::LOGGED_IN
  end

  def destroy?
    update?
  end

  def edit?
    update?
  end

  def update?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      # all users can update their own submissions
      return true if role >= Role::COLLECTION_SUBMITTER &&
          user == item.submitter && item.submitting?

      item.collections.each do |collection|
        # collection managers can update items within their collections
        return true if role >= Role::COLLECTION_MANAGER &&
            user.effective_manager?(collection)
        # unit admins can update items within their units
        collection.units.each do |unit|
          return true if role >= Role::UNIT_ADMINISTRATOR &&
              user.effective_unit_admin?(unit)
        end
      end
    end
    false
  end

end
