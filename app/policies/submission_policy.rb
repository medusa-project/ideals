# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy

  attr_reader :user, :item

  ##
  # @param user [User]
  # @param item [Item]
  #
  def initialize(user, item)
    @user = user
    @item = item
  end

  def agreement?
    !user.nil?
  end

  def create?
    !user.nil?
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
      return true if user.sysadmin?
      # all users can update their own submissions
      return true if user == item.submitter && !item.in_archive

      item.all_collections.each do |collection|
        # collection managers can update items within their collections
        return true if user.manager?(collection)
        # unit admins can update items within their units
        collection.all_units.each do |unit|
          return true if user.unit_admin?(unit)
        end
      end
    end
    false
  end

end
