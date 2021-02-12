# frozen_string_literal: true

class CollectionItemMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :item
end
