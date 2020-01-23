##
# Encapsulates a relationship between an {Item} and a {Collection}, mainly for
# the purpose of tracking which {Collection} is an {Item}'s primary.
#
class ItemCollectionRelationship < ApplicationRecord
  belongs_to :item
  belongs_to :collection

  validates_uniqueness_of :primary, scope: :item_id
end
