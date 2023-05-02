# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the SAML
# authentication strategy.
#
class SamlUser < User

  ##
  # @return [SamlUser]
  #
  def self.from_omniauth(auth)
    auth = auth.deep_stringify_keys
    user = SamlUser.find_by(uid: auth['uid'])
    if user
      user.update_with_omniauth(auth)
    else
      user = SamlUser.create_with_omniauth(auth)
    end
    user
  end

  def self.create_with_omniauth(auth)
    user = SamlUser.new
    user.update_with_omniauth(auth)
    user
  end

  ##
  # @return [Boolean]
  #
  def sysadmin?
    false # TODO: fix this
  end

  def update_with_omniauth(auth)
    auth = auth.deep_stringify_keys
    # By design, logging in overwrites certain existing user properties with
    # current information from the IdP. By supplying this custom attribute,
    # we can preserve the user properties that are set up in test fixture data.
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"

    self.uid         = auth['uid']
    self.email       = auth.dig("extra", "raw_info", "attributes", "emailAddress")&.first
    self.name        = [auth.dig("extra", "raw_info", "attributes", "firstName")&.first,
                        auth.dig("extra", "raw_info", "attributes", "lastName")&.first].join(" ").strip
    self.name        = nil if self.name.blank?
    org_id           = auth.dig("extra", "raw_info", "attributes", "http://eduserv.org.uk/federation/attributes/1.0/organisationid")&.first
    self.institution = Institution.find_by_openathens_organization_id(org_id) if org_id
    self.phone       = auth.dig("extra", "raw_info", "attributes", "telephoneNumber")&.first
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         detail: "[user: #{self.as_json}]\n[auth hash: #{auth.as_json}]",
                                         user:   self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?
    end
  end

end
