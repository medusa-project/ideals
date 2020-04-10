##
# Term in a {Vocabulary}.
#
class VocabularyTerm

  attr_reader :stored_value, :displayed_value

  ##
  # @param stored_value [String]
  # @param displayed_value [String]
  #
  def initialize(stored_value, displayed_value)
    @stored_value    = stored_value
    @displayed_value = displayed_value
  end

end
