# frozen_string_literal: true

##
# Encapsulates a {User} login event.
#
# N.B.: it is debatable whether this should be more strongly related to
# {Event}--perhaps a subclass.
#
# # Attributes
#
# * `auth_hash`   Serialized OmniAuth hash.
# * `auth_method` One of the {Login::Provider} constant values, extracted from
#                 {auth_hash}. TODO: rename to provider
# * `created_at`  Represents the login time. Managed by ActiveRecord.
# * `hostname`    Client hostname.
# * `ip_address`  Client IP address.
# * `updated_at`  Managed by ActiveRecord.
#
class Login < ApplicationRecord

  class Provider
    # Credentials are stored in the `local_identities` table.
    LOCAL      = 0
    # Used only by UIUC.
    SHIBBOLETH = 1
    # Used by many CARLI member institutions.
    SAML       = 2

    def self.all
      self.constants.map{ |c| self.const_get(c) }.sort
    end

    def self.label_for(value)
      case value
      when LOCAL
        "Local"
      when SAML
        "SAML"
      when SHIBBOLETH
        "Shibboleth"
      else
        "Unknown"
      end
    end
  end

  belongs_to :user

  serialize :auth_hash, JSON

  def auth_hash=(auth)
    # By default, omniauth-saml's auth hash is not serializable--it will raise
    # a StackLevelTooDeep error which is probably a bug. So we will discard the
    # parts that are causing problems (which are fortunately irrelevant).
    if auth[:provider] == "saml" && auth.dig(:extra, :raw_info)
      auth = auth.deep_symbolize_keys
      auth[:extra][:raw_info]        = auth[:extra][:raw_info].attributes
      auth[:extra][:response_object] = nil
    end

    case auth[:provider]
    when "shibboleth", "developer"
      self.auth_method = Provider::SHIBBOLETH
    when "saml"
      self.auth_method = Provider::SAML
    when "identity"
      self.auth_method = Provider::LOCAL
    end

    super(auth)
  end

end
