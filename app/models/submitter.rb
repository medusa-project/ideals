# frozen_string_literal: true

class Submitter < ApplicationRecord
  belongs_to :user
  belongs_to :collection
end
