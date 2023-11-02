# frozen_string_literal: true

##
# Designates a {User} as an administrator of an {Institution}. A user can
# administer zero or more institutions, and an institution can be
# administered by zero or more users.
#
class InstitutionAdministrator < ApplicationRecord
  belongs_to :institution
  belongs_to :user
end
