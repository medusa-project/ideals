# frozen_string_literal: true

##
# In IDEALS, it is sometimes necessary for a user to "role play" as someone
# with different privileges, in order to "see" what a user with those
# privileges would "see." [Pundit](https://github.com/varvet/pundit)'s
# policy class methods accept only two arguments: a policy subject and a policy
# target. In a more typical application, the subject would be a {User}, but in
# this application, it is an instance of this class, which bundles a {User} and
# a {Role} (indicating a "privilege limit") together into one object.
#
# (See "Additional context" in the
# [Pundit README](https://github.com/varvet/pundit/blob/master/README.md)).
#
class RequestContext

  ##
  # Institution associated with the `X-Forwarded-Host`  request header.
  #
  # @return [Institution]
  #
  attr_accessor :institution

  ##
  # @return [User] Client user.
  #
  attr_accessor :user

  ##
  # One of the {Role} constant values indicating the limit of the {user}'s
  # privileges. For example, if the user is a {User#sysadmin? system
  # administrator}, but the role limit is {Role#COLLECTION_MANAGER}, the policy
  # method will consider the user's privileges only up to that level.
  #
  # @return [Integer]
  #
  attr_accessor :role_limit

  ##
  # @param user [User]
  # @param role_limit [Integer]
  #
  def initialize(user:, institution:, role_limit:)
    self.user        = user
    self.institution = institution
    self.role_limit  = role_limit
  end

end
