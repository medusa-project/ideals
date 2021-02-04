# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy
  attr_reader :user, :role, :institution

  ##
  # @param user_context [UserContext]
  # @param institution [Institution]
  #
  def initialize(user_context, institution)
    @user        = user_context&.user
    @role        = user_context&.role_limit
    @institution = institution
  end

  def create?
    index?
  end

  def destroy?
    index?
  end

  def edit?
    update?
  end

  def index?
    if user
      return role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
    end
    false
  end

  def new?
    create?
  end

  def show?
    if user
      return role >= Role::INSTITUTION_ADMINISTRATOR &&
        user.effective_institution_admin?(institution)
    end
    false
  end

  def update?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return true if role >= Role::INSTITUTION_ADMINISTRATOR &&
        user.institution_admin?(institution)
    end
    false
  end

end
