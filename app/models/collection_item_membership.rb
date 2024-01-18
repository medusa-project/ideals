# frozen_string_literal: true

##
# Relates an {Item} to an owning {Collection}.
#
# # Attributes
#
# * `collection_id` Foreign key to {Collection}.
# * `created_at`    Managed by ActiveRecord.
# * `item_id`       Foreign key to {Item}.
# * `primary`       Whether the membership is the item's primary collection
#                   membership. (It can only have one.)
# * `updated_at`    Managed by ActiveRecord.
#
class CollectionItemMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :item
end
