# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  def update?
    user.sysadmin?
  end
end
