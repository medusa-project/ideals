# frozen_string_literal: true

##
# Abstract superclass for commands in the
# [command pattern](https://en.wikipedia.org/wiki/Command_pattern).
# The reason for using this pattern is to encapsulate object mutation along
# with recording of audit information.
#
# It would be simpler to do a basic version of auditing using ActiveRecord
# callbacks, but this approach may be limited when considering associations and
# complex updates.
#
class Command

  def execute
    raise "Subclasses must override execute()"
  end

end
