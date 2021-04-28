##
# Associates a {Collection} with a {UserGroup} allowed to manage it.
#
class ManagerGroup < ApplicationRecord
  belongs_to :collection
  belongs_to :user_group
end
