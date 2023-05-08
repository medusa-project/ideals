# frozen_string_literal: true

##
# Encapsulates a {User} login event.
#
# # Attributes
#
# * `auth_hash`   Serialized OmniAuth hash.
# * `auth_method` One of the {User::AuthMethod} constant values, extracted from
#                 {auth_hash}.
# * `created_at`  Represents the login time. Managed by ActiveRecord.
# * `hostname`    Client hostname.
# * `ip_address`  Client IP address.
# * `updated_at`  Managed by ActiveRecord.
#
class Login < ApplicationRecord

  belongs_to :user

  serialize :auth_hash, JSON

end
