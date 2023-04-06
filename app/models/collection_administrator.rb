# frozen_string_literal: true

class CollectionAdministrator < ApplicationRecord
  belongs_to :user
  belongs_to :collection
end
