##
# Encapsulates a relationship between a {Collection} and a {Unit}, mainly for
# the purpose of tracking which {Unit} is a {Collection}'s default.
#
class CollectionUnitRelationship < ApplicationRecord
  belongs_to :collection
  belongs_to :unit

  validates_uniqueness_of :primary, scope: :collection_id
end
