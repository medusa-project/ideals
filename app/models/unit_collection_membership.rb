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
# * 'unit_default'  Whether the collection is the unit's "default", i.e. the
#                   one that was created at the same time the unit was created.
# * `unit_id`       Foreign key to {Unit}.
# * `updated_at`    Managed by ActiveRecord.
#
class UnitCollectionMembership < ApplicationRecord
  belongs_to :unit
  belongs_to :collection

  after_save :ensure_default_uniqueness, if: -> { self.unit_default }


  private

  ##
  # Sets other instances with the same primary unit as "not unit-default" if
  # the instance is marked as unit-default.
  #
  def ensure_default_uniqueness
    UnitCollectionMembership.
      where(unit_id: self.unit_id).
      where("collection_id != ?", self.collection_id).
      where(unit_default: true).
      update_all(unit_default: false)
  end

end
