# frozen_string_literal: true

##
# Encapsulates a {User} login event.
#
# # Attributes
#
# * `auth_hash`      Serialized OmniAuth hash.
# * `created_at`     Represents the login time. Managed by ActiveRecord.
# * `hostname`       Client hostname.
# * `institution_id` Foreign key to {Institution} representing the
#                    institutional context within which the login occurred.
# * `ip_address`     Client IP address.
# * `provider`       One of the {Login::Provider} constant values, extracted
#                    from {auth_hash}.
# * `updated_at`     Managed by ActiveRecord.
#
class Login < ApplicationRecord

  class Provider
    LOCAL = 0
    # Used by many CARLI member institutions, and CARLI itself.
    SAML  = 2

    ##
    # @return [Enumerable<Integer>]
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }.sort
    end

    def self.label_for(value)
      case value
      when LOCAL
        "Local"
      when SAML
        "SAML"
      when 1
        # SHIBBOLETH (removed, but there are still some old Logins in the
        # database associated with this provider)
        "Shibboleth"
      else
        "Unknown"
      end
    end
  end

  has_one :event
  belongs_to :institution
  belongs_to :user

  serialize :auth_hash, coder: JSON

  validates :provider, inclusion: { in: Provider.all }

  after_create :create_event

  ##
  # Override to ensure that the argument is serializable.
  #
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
    when "saml", "developer"
      self.provider = Provider::SAML
    when "identity"
      self.provider = Provider::LOCAL
    end
    super(auth)
  end


  private

  ##
  # Creates an {Event}.
  #
  def create_event
    Event.create!(login:       self,
                  event_type:  Event::Type::LOGIN,
                  institution: self.institution,
                  user:        user,
                  happened_at: Time.now)
  end

end
