# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  attr_reader :user, :role, :collection

  ##
  # @param request_context [RequestContext]
  # @param collection [Collection]
  #
  def initialize(request_context, collection)
    @user       = request_context&.user
    @role       = request_context&.role_limit || Role::NO_LIMIT
    @collection = collection
  end

  ##
  # Invoked from {CollectionsController#update} to ensure that a user cannot
  # move a collection to another collection of which s/he is not an effective
  # manager.
  #
  def change_parent?(new_parent_id)
    if user
      return true if new_parent_id == collection.parent_id
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      if role >= Role::COLLECTION_MANAGER
        return user.effective_manager?(Collection.find(new_parent_id))
      end
    end
    false
  end

  def children?
    true
  end

  def create?
    return false unless user
    if role >= Role::SYSTEM_ADMINISTRATOR
      return true if user.sysadmin? ||
          (collection.is_a?(Collection) && user.effective_manager?(collection))
    elsif role >= Role::COLLECTION_MANAGER
      return true if collection.is_a?(Collection) &&
          user.effective_manager?(collection)
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

  ##
  # N.B.: this method doesn't correspond to a controller method.
  #
  def review_submissions?
    show_properties?
  end

  def show?
    true
  end

  ##
  # N.B.: this method doesn't correspond to a controller method.
  #
  def show_properties?
    role && role >= Role::COLLECTION_MANAGER &&
        user&.effective_manager?(collection)
  end

  def statistics?
    show_properties?
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
