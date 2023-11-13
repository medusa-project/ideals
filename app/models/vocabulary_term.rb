# frozen_string_literal: true

##
# Term within a {Vocabulary}.
#
# When advanced-searching and entering metadata, terms appear in a `select`
# menu. The {displayed_value} is what the user sees in the menu. The
# {stored_value} is stored in an {AscribedElement}'s
# {AscribedElement#string string}.
#
# # Attributes
#
# * `created_at`      Managed by ActiveRecord.
# * `displayed_value` Displayed value.
# * `stored_value`    Stored value.
# * `updated_at`      Managed by ActiveRecord.
# * `vocabulary_id`   Foreign key to the owning {Vocabulary}.
#
class VocabularyTerm < ApplicationRecord

  belongs_to :vocabulary, touch: true

  normalizes :displayed_value, :stored_value, with: -> (value) { value.squish }

  # uniqueness enforced by database unique index
  validates :displayed_value, presence: true

  # uniqueness enforced by database unique index
  validates :stored_value, presence: true

end
