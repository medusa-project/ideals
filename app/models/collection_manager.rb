# frozen_string_literal: true

class CollectionManager < ApplicationRecord
  belongs_to :user
  belongs_to :collection
end
