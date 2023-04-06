# frozen_string_literal: true

##
# Conceptual "role" into which a {User} can be categorized. This exists mainly
# to support "role playing": for example, a system administrator masquerading
# as a lesser-privileged user (like a collection administrator) in order to
# view a web page as a lesser-privileged user would see it, without having to
# literally alter their own privileges.
#
# @see RequestContext
#
class Role

  # N.B.: Values need to be comparable, i.e. a more privileged role needs to be
  # greater than a lesser role. They are also persisted in the session, so they
  # must be changed carefully.
  NO_LIMIT                  = 1000
  SYSTEM_ADMINISTRATOR      = 300
  INSTITUTION_ADMINISTRATOR = 250
  UNIT_ADMINISTRATOR        = 200
  COLLECTION_ADMINISTRATOR  = 150
  COLLECTION_SUBMITTER      = 100
  LOGGED_IN                 = 50
  LOGGED_OUT                = 0

  ##
  # @return [Enumerable<Integer>]
  #
  def self.all
    Role.constants.map { |c| Role.const_get(c) }
  end

  ##
  # @param value [Integer] One of the constant values.
  # @return [String] English label for the value.
  #
  def self.label(value)
    case value
    when 300
      "System Administrator"
    when 250
      "Institution Administrator"
    when 200
      "Unit Administrator"
    when 150
      "Collection Administrator"
    when 100
      "Collection Submitter"
    when 50
      "Logged In"
    when 0
      "Logged Out"
    else
      "No Limit"
    end
  end

end
