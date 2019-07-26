# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.

    user ||= User::Shibboleth.new # guest user (not logged in)

    if user.is?(Ideals::UserRole::ADMIN)
      can :manage, :all
    elsif user.is?(Ideals::UserRole::MANAGER)
      manager_from_user = Manager.from_user(user)
      raise "user with manager role not found in manager query #{user.provider} | #{user.uid}" unless manager_from_user

      can :create, Collection
      can :manage, Collection do |collection|
        collection.try(collection.managers.include?(manager_from_user))
      end
      can [:view, :release_collection], Manager do |viewable_manager|
        viewable_manager.try(manager_from_user == viewable_manager)
      end
    end
  end
end
