# frozen_string_literal: true

##
# Designates a {User} as an administrator of a {Unit}. A user can administer
# zero or more units, and a unit can be administered by one or more users.
#
class UnitAdministrator < ApplicationRecord
  belongs_to :unit
  belongs_to :user
end
