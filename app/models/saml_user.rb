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
    auth  = auth.deep_stringify_keys
    email = auth['extra']['raw_info'].attributes[:emailAddress]&.first
    user  = SamlUser.find_by(email: email)
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
    # This is an OmniAuth::AuthHash
    auth = auth.deep_stringify_keys
    # This is a Hash
    attrs = auth['extra']['raw_info'].attributes
    # By design, logging in overwrites certain existing user properties with
    # current information from the IdP. By supplying this custom attribute,
    # we can preserve the user properties that are set up in test fixture data.
    return if attrs['overwriteUserAttrs'] == "false"

    self.email       = attrs[:emailAddress]&.first
    self.name        = [attrs[:firstName]&.first, attrs[:lastName]&.first].join(" ").strip
    self.name        = self.email if self.name.blank?
    org_id           = attrs[:"http://eduserv.org.uk/federation/attributes/1.0/organisationid"]
    self.institution = Institution.find_by_openathens_organization_id(org_id) if org_id
    self.phone       = attrs[:phoneNumber]&.first
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         detail: "[user: #{YAML::dump(self)}]\n"\
                                                 "[auth hash: #{YAML::dump(auth)}]",
                                         user:   self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?
    end
  end

end
