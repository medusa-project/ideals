##
# Defines an ordered list of {MetadataProfileElement metadata elements}, their
# labels, and whether they are searchable, sortable, etc.
#
# The elements specified in a metadata profile are a snapshot of the same
# institution's {RegisteredElement element registry} at the time of its
# creation.
#
# A metadata profile can be assigned to {Collection}s and {Unit}s. Collections
# without an assigned profile will fall back to the parent unit's profile, and
# then to the {MetadataProfile#institution_default institution's default
# profile}.
#
# A metadata profile is like a template or view. Instead of enumerating an
# {Item}'s metadata elements for public display, for example, we enumerate the
# elements in its {Collection}'s metadata profile, and display each of the ones
# that match, in profile order.
#
# # Attributes
#
# * `name`                        The name of the metadata profile. Must be
#                                 unique within the same institution.
# * `created_at`                  Managed by ActiveRecord.
# * `full_text_relevance_weight`  Weight of the full text field when computing
#                                 a result relevance score. See
#                                 {MetadataProfileElement#relevance_weight}.
# * `institution_default`         Whether the metadata profile is used by
#                                 {Collection}s without a metadata profile
#                                 assigned, or in cross-collection contexts.
#                                 (Only one metadata profile can be marked as
#                                 such per institution--this is enforced by an
#                                 `after_save` callback.)
# * `updated_at`                  Managed by ActiveRecord.
#
class MetadataProfile < ApplicationRecord
  include Breadcrumb

  belongs_to :institution, optional: true

  has_many :collections, inverse_of: :metadata_profile
  has_many :elements, -> { order(:position) },
           class_name: "MetadataProfileElement", inverse_of: :metadata_profile,
           dependent: :destroy
  has_many :units, inverse_of: :metadata_profile,
           dependent: :restrict_with_exception

  validates :full_text_relevance_weight, numericality: { only_integer: true,
                                                         greater_than_or_equal_to: MetadataProfileElement::MIN_RELEVANCE_WEIGHT,
                                                         less_than_or_equal_to: MetadataProfileElement::MAX_RELEVANCE_WEIGHT }

  validates :name, presence: true, length: { minimum: 2 }

  after_save :ensure_default_uniqueness

  ##
  # @return [MetadataProfile] The global profile, used in cross-institution
  #                           contexts.
  #
  def self.global
    MetadataProfile.find_by(institution_id: nil)
  end

  ##
  # Ascribes {MetadataProfileElement}s corresponding to all
  # {RegisteredElement}s in the same institution to a newly created profile.
  #
  def add_all_registered_elements
    raise "Instance already has elements ascribed to it" if self.elements.any?
    self.institution.registered_elements.order(:label).each_with_index do |reg_e, index|
      self.elements.build(registered_element: reg_e,
                          position:           index,
                          relevance_weight:   MetadataProfileElement::DEFAULT_RELEVANCE_WEIGHT,
                          visible:            true,
                          searchable:         true,
                          sortable:           true,
                          faceted:            reg_e == self.institution.author_element)
    end
    self.save!
  end

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    MetadataProfile
  end

  ##
  # Overrides parent to intelligently clone an instance including all of its
  # elements.
  #
  # @return [MetadataProfile]
  #
  def dup
    clone                     = super
    clone.name                = "Clone of #{self.name}"
    clone.institution_default = false
    # The instance requires an ID for MetadataProfileElement validations.
    clone.save!
    self.elements.each { |e| clone.elements << e.dup }
    clone
  end

  ##
  # @return [Enumerable<MetadataProfileElement>]
  #
  def faceted_elements
    self.elements.where(faceted: true).order(:position)
  end

  ##
  # @return [Boolean] Whether the instance is the global profile.
  #
  def global?
    institution_id.nil?
  end


  private

  ##
  # Sets all other instances within the same institution as "not default" if
  # the instance is marked as default.
  #
  def ensure_default_uniqueness
    if self.institution_default
      self.class.all.
        where(institution_id: self.institution_id).
        where("id != ?", self.id).each do |instance|
        instance.update!(institution_default: false)
      end
    end
  end

end
