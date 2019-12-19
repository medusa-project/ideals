# frozen_string_literal: true

class Manager < ApplicationRecord
  belongs_to :role
  belongs_to :collection
end
