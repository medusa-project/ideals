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

  belongs_to :institution

  has_many :collections, inverse_of: :metadata_profile,
           dependent: :restrict_with_exception
  has_many :elements, -> { order(:index) },
           class_name: "MetadataProfileElement", inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  ##
  # @return [MetadataProfile] Default metadata profile.
  #
  def self.default
    MetadataProfile.find_by_default(true)
  end

  ##
  # Ascribes some baseline [MetadataProfileElement]s to a newly created
  # profile.
  #
  def add_default_elements
    raise "Instance already has elements ascribed to it" if self.elements.any?
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                        index:              0,
                        visible:            true,
                        searchable:         true,
                        sortable:           true,
                        faceted:            false,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                        index:              1,
                        visible:            true,
                        searchable:         true,
                        sortable:           true,
                        faceted:            true,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                        index:              2,
                        visible:            true,
                        searchable:         true,
                        sortable:           true,
                        faceted:            true,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor"),
                        index:              3,
                        visible:            true,
                        searchable:         true,
                        sortable:           false,
                        faceted:            false,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:abstract"),
                        index:              4,
                        visible:            true,
                        searchable:         true,
                        sortable:           false,
                        faceted:            false,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                        index:              5,
                        visible:            true,
                        searchable:         true,
                        sortable:           true,
                        faceted:            false,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:uri"),
                        index:              6,
                        visible:            true,
                        searchable:         true,
                        sortable:           false,
                        faceted:            false,
                        indexed:            true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                        index:              7,
                        visible:            true,
                        searchable:         true,
                        sortable:           false,
                        faceted:            true,
                        indexed:            true)
    self.save!
  end

  def breadcrumb_label
    name
  end

  ##
  # Overrides parent to intelligently clone an instance including all of its
  # elements.
  #
  # @return [MetadataProfile]
  #
  def dup
    clone = super
    clone.name = "Clone of #{self.name}"
    clone.default = false
    # The instance requires an ID for MetadataProfileElement validations.
    clone.save!
    self.elements.each { |e| clone.elements << e.dup }
    clone
  end

  ##
  # @return [Enumerable<MetadataProfileElement>]
  #
  def faceted_elements
    self.elements.where(faceted: true).order(:index)
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
