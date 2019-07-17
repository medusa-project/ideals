# frozen_string_literal: true

class Invitee < ApplicationRecord
  has_many :invitee_notes, inverse_of: :invitee, dependent: :destroy

  accepts_nested_attributes_for :invitee_notes, allow_destroy: true

  validates :email, presence: true, uniqueness: true
  before_destroy :destroy_identity
  before_destroy :destroy_user

  def destroy_identity
    identity = Identity.find_by(email: email)
    identity&.destroy!
  end

  def destroy_user
    user = User::Identity.find_by(email: email)
    user&.destroy!
  end
end
