# frozen_string_literal: true

##
# Term within a {Vocabulary}.
#
# When advanced-searching and entering metadata, terms appear in a `select`
# menu. The {displayed_value} is what the user sees in the menu. The
# {stored_value} is stored in an {AscribedElement}'s
# {AscribedElement#string string}.
#
class VocabularyTerm < ApplicationRecord

  belongs_to :vocabulary, touch: true

  # uniqueness enforced by database constraints
  validates :displayed_value, presence: true

  # uniqueness enforced by database constraints
  validates :stored_value, presence: true

end
