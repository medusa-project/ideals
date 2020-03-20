# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy

  class Scope
    attr_reader :user, :relation

    ##
    # @param user [User]
    # @param relation [ItemRelation]
    #
    def initialize(user, relation)
      @user     = user
      @relation = relation
    end

    ##
    # @return [ItemRelation]
    #
    def resolve
      if user&.sysadmin?
        relation
      else
        relation.filter(Item::IndexFields::DISCOVERABLE, true).
            filter(Item::IndexFields::SUBMITTING, false).
            filter(Item::IndexFields::WITHDRAWN, false)
      end
    end
  end

  attr_reader :user, :item

  ##
  # @param user [User]
  # @param item [Item]
  #
  def initialize(user, item)
    @user = user
    @item = item
  end

  def cancel_submission?
    update?
  end

  def create?
    !user.nil?
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
    @user&.sysadmin? || (@item.discoverable && !@item.withdrawn && !@item.submitting)
  end

  ##
  # N.B.: this is not a controller method.
  #
  def show_access?
    # user must be logged in
    if user
      # sysadmins can see access
      return true if user.sysadmin?

      item.all_collections.each do |collection|
        # collection managers can see access of items within their collections
        return true if user.effective_manager?(collection)
        # unit admins can see access of items within their units
        collection.all_units.each do |unit|
          return true if user.effective_unit_admin?(unit)
        end
      end
    end
    false
  end

  def show_all_metadata?
    show_access?
  end

  def update?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if user.sysadmin?
      # all users can update their own submissions
      return true if user == item.submitter && item.submitting

      item.all_collections.each do |collection|
        # collection managers can update items within their collections
        return true if user.effective_manager?(collection)
        # unit admins can update items within their units
        collection.all_units.each do |unit|
          return true if user.effective_unit_admin?(unit)
        end
      end
    end
    false
  end

end
