# frozen_string_literal: true

class Invitee < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  before_destroy :destroy_identity
  before_destroy :destroy_user

  def self.pendings
    Invitee.where(approval_state: Ideals::ApprovalState::PENDING)
  end

  def self.approveds
    Invitee.where(approval_state: Ideals::ApprovalState::APPROVED)
  end

  def self.rejecteds
    Invitee.where(approval_state: Ideals::ApprovalState::REJECTED)
  end

  def destroy_identity
    identity = Identity.find_by(email: email)
    identity&.destroy!
  end

  def destroy_user
    user = User::Identity.find_by(email: email)
    user&.destroy!
  end
end
