# frozen_string_literal: true

class UnitPolicy
  attr_reader :user, :unit

  def initialize(user, unit)
    @user = user
    @unit = unit
  end

  def update?
    user.sysadmin?
  end
end