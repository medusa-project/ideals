# frozen_string_literal: true

class CollectionSubmitter < ApplicationRecord
  belongs_to :user
  belongs_to :collection
end
