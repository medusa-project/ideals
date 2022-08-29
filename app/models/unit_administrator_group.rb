##
# Associates a [Unit] with a [UserGroup] allowed to administer it.
#
class UnitAdministratorGroup < ApplicationRecord
  belongs_to :unit
  belongs_to :user_group
end
