# frozen_string_literal: true

##
# Encapsulates a {RegisteredElement}-query term pair attached to a
# {PrebuiltSearch}.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `prebuilt_search_id`    Foreign key to {PrebuiltSearch}.
# * `registered_element_id` Foreign key to {RegisteredElement}.
# * `term`                  Query term to search for within the element
#                           identified by {registered_element_id}.
# * `updated_at`            Managed by ActiveRecord.
#
class PrebuiltSearchElement < ApplicationRecord

  belongs_to :prebuilt_search
  belongs_to :registered_element

  normalizes :term, with: -> (value) { value.squish }

  validates :term, presence: true

end
