class MetadataProfile < ApplicationRecord
  include Breadcrumb

  has_many :collections, inverse_of: :metadata_profile

  validates_presence_of :name

  after_save :ensure_default_uniqueness

  def label
    name
  end

  private

  ##
  # Sets all other instances as "not default" if the instance is marked as
  # default.
  #
  def ensure_default_uniqueness
    if self.default
      self.class.all.where('id != ?', self.id).each do |instance|
        instance.update!(default: false)
      end
    end
  end

end
