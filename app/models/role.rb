# frozen_string_literal: true

##
# Conceptual "role" into which a {User} can be categorized. This exists mainly
# to support "role playing": for example, a system administrator masquerading
# as a lesser-privileged user (like a collection manager) in order to "see"
# what they "see" without having to literally alter their own privileges.
#
# @see UserContext
#
class Role

  # N.B.: Values need to be comparable, i.e. a greater role needs to be greater
  # than a lesser role. They are also persisted in the session, so they must
  # be changed carefully.
  NO_LIMIT             = 100
  SYSTEM_ADMINISTRATOR = 50
  UNIT_ADMINISTRATOR   = 30
  COLLECTION_MANAGER   = 20
  COLLECTION_SUBMITTER = 10
  LOGGED_IN            = 5
  LOGGED_OUT           = 0

  ##
  # @param value [Integer] One of the constant values.
  # @return [String] English label for the value.
  #
  def self.label(value)
    case value
    when 50
      "System Administrator"
    when 30
      "Unit Administrator"
    when 20
      "Collection Manager"
    when 10
      "Collection Submitter"
    when 5
      "Logged In"
    when 0
      "Logged Out"
    else
      "Default"
    end
  end

end
