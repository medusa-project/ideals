# frozen_string_literal: true

##
# Join model that represents a membership of a {Collection} within a {Unit}.
#
# # Attributes
#
# * `created_at`    Managed by ActiveRecord.
# * `collection_id` Foreign key to {Collection}
# * `primary`       Whether, when the collection belongs to more than one unit,
#                   the membership is the primary one.
# * `unit_id`       Foreign key to {Unit}.
# * `updated_at`    Managed by ActiveRecord.
#
class UnitCollectionMembership < ApplicationRecord

  belongs_to :unit
  belongs_to :collection

end
