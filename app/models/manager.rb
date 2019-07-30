class Manager < ApplicationRecord
  has_and_belongs_to_many :collections, inverse_of: :managers

  def take_on_collection(collection)
    collections << collection
  end

  def release_collection(collection)
    collections.delete(collection)
  end

  def provider_uid
    "#{provider} | #{uid}"
  end

  def self.from_user(user)
    Manager.find_by(provider: user.provider, uid: user.uid)
  end

end
