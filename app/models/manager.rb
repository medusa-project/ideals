# frozen_string_literal: true

class Manager < ApplicationRecord
  belongs_to :user
  belongs_to :collection
end
