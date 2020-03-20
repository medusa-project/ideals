# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  attr_reader :user, :collection

  ##
  # @param user [User]
  # @param collection [Collection]
  #
  def initialize(user, collection)
    @user       = user
    @collection = collection
  end

  def create?
    return false unless user
    user.sysadmin? ||                                                  # user is sysadmin
        collection.all_units.find{ |unit| @user.unit_admin?(unit) } || # user is unit admin
        user.manager?(collection)                                      # user is collection manager
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
  # N.B.: this method doesn't correspond to a controller method.
  #
  def submit_item?
    return false unless user
    user.sysadmin? ||                                                  # user is sysadmin
        collection.all_units.find{ |unit| @user.unit_admin?(unit) } || # user is unit admin
        user.manager?(collection) ||                                   # user is collection manager
        user.submitter?(collection)                                    # user is collection submitter
  end

  def update?
    create?
  end
end
