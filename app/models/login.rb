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

  def auth_hash=(auth)
    # By default, omniauth-saml's auth hash is not serializable--it will raise
    # a StackLevelTooDeep error which is probably a bug. So we will discard the
    # parts that are causing problems (which are fortunately irrelevant).
    if auth[:provider] == "saml"
      auth = auth.deep_symbolize_keys
      auth[:extra][:raw_info]        = auth[:extra][:raw_info].attributes
      auth[:extra][:response_object] = nil
    end
    super(auth)
  end

end
