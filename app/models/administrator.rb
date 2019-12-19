# frozen_string_literal: true

class Administrator < ApplicationRecord
  belongs_to :role
  belongs_to :unit
end
