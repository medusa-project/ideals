# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.

    user ||= User::Shibboleth.new # guest user (not logged in)

    if user.is?(Ideals::UserRole::ADMIN)
      can :manage, :all
    else
      can :login, Identity
    end
  end
end
