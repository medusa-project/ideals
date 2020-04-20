# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  attr_reader :user, :role, :collection

  ##
  # @param user_context [UserContext]
  # @param collection [Collection]
  #
  def initialize(user_context, collection)
    @user       = user_context&.user
    @role       = user_context&.role_limit || Role::NO_LIMIT
    @collection = collection
  end

  def children?
    true
  end

  def create?
    return false unless user
    if role >= Role::SYSTEM_ADMINISTRATOR
      return true if user.sysadmin? || user.effective_manager?(collection)
    elsif role >= Role::COLLECTION_MANAGER
      return true if user.effective_manager?(collection)
    end
    false
  end

  def destroy?
    create?
  end

  def edit_access?
    update?
  end

  def edit_collection_membership?
    update?
  end

  def edit_properties?
    update?
  end

  def edit_unit_membership?
    update?
  end

  def index?
    true
  end

  def new?
    create?
  end

  def show?
    true
  end

  ##
  # N.B.: this method is used in views and does not correspond to a controller
  # method.
  #
  def show_properties?
    role && role >= Role::COLLECTION_MANAGER &&
        user&.effective_manager?(collection)
  end

  ##
  # N.B.: this method doesn't correspond to a controller method.
  #
  def submit_item?
    return false unless user
    if role >= Role::SYSTEM_ADMINISTRATOR
      return true if user.sysadmin? ||
          user.effective_manager?(collection) ||
          user.effective_submitter?(collection)
    elsif role >= Role::COLLECTION_MANAGER
      return true if user.effective_manager?(collection) ||
          user.effective_submitter?(collection)
    elsif role >= Role::COLLECTION_SUBMITTER
      return true if user.effective_submitter?(collection)
    end
    false
  end

  def update?
    create?
  end
end
