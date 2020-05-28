# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy

  class Scope
    attr_reader :user, :role, :relation

    ##
    # @param user_context [UserContext]
    # @param relation [ItemRelation]
    #
    def initialize(user_context, relation)
      @user     = user_context&.user
      @role     = user_context&.role_limit || Role::NO_LIMIT
      @relation = relation
    end

    ##
    # @return [ItemRelation]
    #
    def resolve
      if role >= Role::SYSTEM_ADMINISTRATOR && user&.sysadmin?
        relation
      else
        relation.filter(Item::IndexFields::DISCOVERABLE, true).
            filter(Item::IndexFields::SUBMITTING, false).
            filter(Item::IndexFields::WITHDRAWN, false)
      end
    end
  end

  attr_reader :user, :role, :item

  ##
  # @param user_context [UserContext]
  # @param item [Item]
  #
  def initialize(user_context, item)
    @user = user_context&.user
    @role = user_context&.role_limit
    @item = item
  end

  def cancel_submission?
    update?
  end

  def create?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?

      item.all_collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return true if role >= Role::COLLECTION_SUBMITTER &&
            user.effective_submitter?(collection)
      end
    end
    false
  end

  ##
  # N.B.: this is used by {BitstreamsController}.
  #
  def data?
    show?
  end

  def destroy?
    update?
  end

  def edit_membership?
    update?
  end

  def edit_metadata?
    update?
  end

  def edit_properties?
    update?
  end

  def index?
    true
  end

  def show?
    (role && role >= Role::SYSTEM_ADMINISTRATOR && user&.sysadmin?) ||
        (@item.discoverable && !@item.withdrawn && !@item.submitting)
  end

  ##
  # N.B.: this is not a controller method.
  #
  def show_access?
    # user must be logged in
    if user
      if role >= Role::SYSTEM_ADMINISTRATOR
        # sysadmins can see access
        return true if user.sysadmin?
      end
      item.all_collections.each do |collection|
        # collection managers can see access of items within their collections
        return true if role >= Role::COLLECTION_MANAGER &&
            user.effective_manager?(collection)
        # unit admins can see access of items within their units
        collection.all_units.each do |unit|
          return true if role >= Role::UNIT_ADMINISTRATOR &&
              user.effective_unit_admin?(unit)
        end
      end
    end
    false
  end

  def show_all_metadata?
    show_access?
  end

  ##
  # N.B.: this is used only in views and doesn't correspond to a controller
  # method.
  #
  def show_sysadmin_content?
    role && role >= Role::SYSTEM_ADMINISTRATOR && user&.sysadmin?
  end

  def update?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      # all users can update their own submissions
      return true if role >= Role::COLLECTION_SUBMITTER &&
          user == item.submitter && item.submitting

      item.all_collections.each do |collection|
        # unit admins can update items within their units
        collection.all_units.each do |unit|
          return true if role >= Role::UNIT_ADMINISTRATOR &&
              user.effective_unit_admin?(unit)
        end
        # collection managers can update items within their collections
        return true if role >= Role::COLLECTION_MANAGER &&
            user.effective_manager?(collection)
      end
    end
    false
  end

end
