# frozen_string_literal: true

class Administrator < ApplicationRecord
  belongs_to :unit
  belongs_to :user, class_name: "User::User"
end
