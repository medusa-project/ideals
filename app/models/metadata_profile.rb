##
# Defines an ordered list of {RegisteredElement metadata elements}, their
# labels, and whether they are searchable, sortable, etc. A metadata profile
# can be assigned to a {Collection}. Collections without an assigned profile
# will use the default profile--the single profile whose `default` property
# is set to `true`.
#
# A metadata profile is like a template or view. Instead of enumerating an
# {Item}'s metadata elements for public display, for example, we enumerate the
# elements in its {Collection}'s metadata profile, and display each of the ones
# that match in profile order.
#
# N.B.: the idea for a "metadata profile" comes from
# [Kumquat](https://github.com/medusa-project/kumquat). As of this writing,
# this class and Kumquat's same-named equivalent are very similar in both
# concept and implementation.
#
# # Attributes
#
# * `name`                        The name of the metadata profile.
# * `created_at`                  Managed by ActiveRecord.
# * `default`                     Whether the metadata profile is used by
#                                 {Collection}s without a metadata profile
#                                 assigned, or in cross-collection contexts.
#                                 (Only one metadata profile can be marked
#                                 default--this is enforced by an `after_save`
#                                 callback.)
# * `updated_at`                  Managed by ActiveRecord.
#
class MetadataProfile < ApplicationRecord
  include Breadcrumb

  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_exception
  has_many :elements, -> { order(:index) },
           class_name: "MetadataProfileElement", inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  ##
  # @return [Enumerable<MetadataProfileElement>]
  #
  def facetable_elements
    self.elements.where(facetable: true).order(:index)
  end

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
