##
# Associates a {Collection} with a {UserGroup} allowed to submit to it.
#
class SubmitterGroup < ApplicationRecord
  belongs_to :collection
  belongs_to :user_group
end
