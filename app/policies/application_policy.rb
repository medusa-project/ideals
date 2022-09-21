# frozen_string_literal: true

##
# Abstract base class for policy classes.
#
# Policy classes are based on the design used by
# [Pundit](https://github.com/varvet/pundit), which this application originally
# depended on. Pundit was removed due to its poor support for auth failure
# "reasons," but the basic auth architecture is the same.
#
# A policy class has a two-argument constructor accepting a [RequestContext]
# and any kind of authorizable object. It also contains a number of methods,
# most of them probably named the same as a controller method, but it may also
# contain any other methods, which can be invoked arbitrarily from e.g. helpers
# or views. All of these methods return a hash with an `authorized` key
# (boolean value) and, if not authorized, a `reason` key (string).
#
# For convenience, there is a method interceptor that will respond to calls
# ending in `?` and return a simple boolean value, so e.g. `create()` returns a
# hash but `create?()` returns a boolean.
#
class ApplicationPolicy

  AUTHORIZED_RESULT = { authorized: true }
  LOGGED_OUT_RESULT = { authorized: false, reason: "You must be logged in." }

  attr_reader :role

  ##
  # @param user [User]
  # @param target_institution [Institution]
  # @param role_limit [Integer] One of the [Role] constant values.
  #
  def effective_institution_admin(user, target_institution, role_limit)
    if (!role_limit || role_limit >= Role::INSTITUTION_ADMINISTRATOR) &&
      user&.effective_institution_admin?(target_institution)
      return AUTHORIZED_RESULT
    end
    {
      authorized: false,
      reason: target_institution ?
                "You must be an administrator of #{target_institution.name}." :
                "You must be an institution administrator."
    }
  end

  ##
  # @param user [User]
  # @param role_limit [Integer] One of the [Role] constant values.
  # @return [Hash]
  #
  def effective_sysadmin(user, role_limit)
    if user&.sysadmin?
      return AUTHORIZED_RESULT if !role_limit ||
        role_limit >= Role::SYSTEM_ADMINISTRATOR
    end
    {
      authorized: false,
      reason:     "This action can only be performed by system administrators."
    }
  end

  ##
  # Intercepts methods ending with `?` and routes them to the non-question
  # implementation, returning the value of the `authorized` key.
  #
  def method_missing(symbol, *args)
    method_name = symbol.to_s
    if method_name.end_with?("?")
      no_q_name = method_name[0..-2].to_sym
      if self.respond_to?(no_q_name)
        return self.send(no_q_name, *args)[:authorized]
      end
    end
    super
  end

end
