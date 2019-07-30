# frozen_string_literal: true

class Invitee < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  before_destroy :destroy_identity
  before_destroy :destroy_user
  before_destroy :destroy_manager
  before_create :handle_manager
  before_update :handle_manager

  def destroy_identity
    identity = Identity.find_by(email: email)
    identity&.destroy!
  end

  def destroy_user
    user = User::Identity.find_by(email: email)
    user&.destroy!
  end

  def ensure_manager
    manager = Manager.find_by(provider: Ideals::AuthProvider::IDENTITY, uid: email)
    Manager.create!(provider: Ideals::AuthProvider::IDENTITY, uid: email) unless manager
  end

  def destroy_manager
    manager = Manager.find_by(provider: Ideals::AuthProvider::IDENTITY, uid: email)
    manager.destroy! if manager
  end

  def handle_manager
    if role == Ideals::UserRole::MANAGER && approval_state == Ideals::ApprovalState::APPROVED
      ensure_manager
    else
      destroy_manager
    end
  end
end
