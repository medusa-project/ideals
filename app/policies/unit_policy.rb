# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  def create?
    # user is sysadmin or unit administrator for an ancestor unit

  end
end
