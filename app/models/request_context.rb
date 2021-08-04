# frozen_string_literal: true

##
# Bundles information about a client request for authorization purposes.
#
# (See "Additional context" in the
# [Pundit README](https://github.com/varvet/pundit/blob/master/README.md),
# which is relevant even though we are no longer using Pundit).
#
class RequestContext

  ##
  # Client hostname.
  #
  # @return [String]
  #
  attr_accessor :client_hostname

  ##
  # Client IP address.
  #
  # @return [String]
  #
  attr_accessor :client_ip

  ##
  # Institution associated with the `X-Forwarded-Host`  request header.
  #
  # @return [Institution]
  #
  attr_accessor :institution

  ##
  # @return [User] Client user. This will be `nil` in the case of a client who
  #                is not logged in.
  #
  attr_accessor :user

  ##
  # One of the {Role} constant values indicating the limit of the {User}'s
  # privileges. For example, if the user is a {User#sysadmin? system
  # administrator}, but the role limit is {Role#COLLECTION_MANAGER}, the policy
  # method will consider the user's privileges only up to that level. This
  # enables the user to "role play" as someone with different privileges.
  #
  # @return [Integer]
  #
  attr_accessor :role_limit

  ##
  # @param client_ip [String] The default value makes for more concise tests,
  #                           but a correct value should be provided for normal
  #                           use.
  # @param client_hostname [String] The default value makes for more concise
  #                                 tests, but a correct value should be
  #                                 provided for normal use.
  # @param user [User] The logged-in user, if one exists.
  # @param institution [Institution]
  # @param role_limit [Integer]
  #
  def initialize(client_ip:       "10.0.0.1",
                 client_hostname: "example.org",
                 user:            nil,
                 institution:     nil,
                 role_limit:      Role::NO_LIMIT)
    self.client_ip       = client_ip
    self.client_hostname = client_hostname
    self.user            = user
    self.institution     = institution
    self.role_limit      = role_limit
  end

end
