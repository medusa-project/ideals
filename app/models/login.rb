# frozen_string_literal: true

##
# Encapsulates a {User} login event.
#
# # Attributes
#
# * `auth_hash`  Serialized OmniAuth hash.
# * `created_at` Represents the login time. Managed by ActiveRecord.
# * `ip_address` Client IP address.
# * `updated_at` Managed by ActiveRecord.
#
class Login < ApplicationRecord

  belongs_to :user

  serialize :auth_hash, JSON

end
