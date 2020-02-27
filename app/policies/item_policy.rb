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
            filter(Item::IndexFields::IN_ARCHIVE, true).
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

  def create?
    user&.sysadmin? # TODO: write this
  end

  def destroy?
    create?
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
    @user&.sysadmin? || (@item.discoverable && !@item.withdrawn && @item.in_archive)
  end

  def update?
    @user&.sysadmin? || (@item.all_collection_managers + @item.all_unit_administrators).include?(@user)
  end

end
