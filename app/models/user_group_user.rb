# frozen_string_literal: true

##
# Encapsulates a direct membership of a {User} within a {UserGroup}.
#
# This class only exists to make certain ActiveRecord operations easier and
# there should be little use for it otherwise.
#
# @see UserGroup#includes?
#
class UserGroupUser < ApplicationRecord

  belongs_to :user_group
  belongs_to :user

  self.table_name = "user_groups_users"

end


