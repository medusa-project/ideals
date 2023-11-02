# frozen_string_literal: true

##
# Associates a {Unit} with a {UserGroup} allowed to administer it.
#
class InstitutionAdministratorGroup < ApplicationRecord
  belongs_to :institution
  belongs_to :user_group
end
