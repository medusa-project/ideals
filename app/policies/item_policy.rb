# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy
  attr_reader :user, :item

  ##
  # @param user [User]
  # @param item [Item]
  #
  def initialize(user, item)
    @user = user
    @item = item
  end

  def edit?
    update?
  end

  def index?
    true
  end

  def show?
    @user&.sysadmin? || (@item.discoverable && !@item.withdrawn && @item.in_archive)
  end

  def update?
    @user&.sysadmin? || (@item.all_collection_managers + @item.all_unit_administrators).include?(@user)
  end

end
