# frozen_string_literal: true

##
# Abstract superclass for commands in the
# [command pattern](https://en.wikipedia.org/wiki/Command_pattern).
# This pattern encapsulates object mutation along with recording of audit
# information (generally with the help of {Event}).
#
# It would be simpler to do a basic version of auditing using ActiveRecord
# callbacks, but this approach is limited when considering associations and
# complex/multi-step updates.
#
class Command

  def execute
    raise "Subclasses must override execute()"
  end

end
