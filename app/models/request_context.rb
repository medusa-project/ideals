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
  # N.B.: this class is required if we want to be able to pass instances to
  # {ActiveJob}s (which we do). We've used `config/initializers/active_job.rb`
  # to tell ActiveJob that this class exists.
  #
  class RequestContextSerializer < ActiveJob::Serializers::ObjectSerializer

    def serialize?(argument)
      argument.kind_of?(RequestContext)
    end

    def serialize(request_context)
      super(
        client_hostname: request_context.client_hostname,
        client_ip:       request_context.client_ip,
        institution:     request_context.institution,
        user:            request_context.user,
        role_limit:      request_context.role_limit
      )
    end

    def deserialize(hash)
      hash = hash.symbolize_keys
      RequestContext.new(client_hostname: hash[:client_hostname],
                         client_ip:       hash[:client_ip],
                         user:            hash[:user],
                         institution:     hash[:institution],
                         role_limit:      hash[:role_limit])
    end

  end

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
  # administrator}, but the role limit is {Role#COLLECTION_ADMINISTRATOR}, the
  # policy method will consider the user's privileges only up to that level.
  # This enables the user to "role play" as someone with different privileges.
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
