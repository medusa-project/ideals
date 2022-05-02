##
# Defines an ordered list of {RegisteredElement metadata elements}, their
# labels, and whether they are required, repeatable, etc., for the purposes of
# submitting an item.
#
# One instance is marked as the default, and is used by all submitters across
# all {Collection}s, but this can be overridden by assigning other profiles to
# specific collections. Collections without an assigned profile will use the
# default profile--the single profile whose `default` property is set to
# `true`.
#
# A submission profile can be thought of as the "input" counterpart to a
# {MetadataProfile}, which is used for "output" purposes. It tells users what
# information must be ascribed to an {Item} when it is submitted.
#
# # Attributes
#
# * `name`                        The name of the submission profile.
# * `created_at`                  Managed by ActiveRecord.
# * `default`                     Whether the submission profile is used by
#                                 {Collection}s without a submission profile
#                                 assigned, or in cross-collection contexts.
#                                 (Only one submission profile can be marked
#                                 default--this is enforced by an `after_save`
#                                 callback.)
# * `updated_at`                  Managed by ActiveRecord.
#
class SubmissionProfile < ApplicationRecord
  include Breadcrumb

  belongs_to :institution

  has_many :collections, inverse_of: :submission_profile,
           dependent: :restrict_with_exception
  has_many :elements, -> { order(:position) },
           class_name: "SubmissionProfileElement",
           inverse_of: :submission_profile,
           dependent: :destroy
  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  ##
  # @return [SubmissionProfile] Default submission profile.
  #
  def self.default
    SubmissionProfile.find_by_default(true)
  end

  ##
  # Ascribes some baseline [SubmissionProfileElement]s to a newly created
  # profile.
  #
  def add_default_elements
    raise "Instance already has elements ascribed to it" if self.elements.any?
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:title"),
                        position:           0,
                        repeatable:         false,
                        required:           true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:issued"),
                        position:           1,
                        repeatable:         true,
                        required:           true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:type"),
                        position:           2,
                        repeatable:         true,
                        required:           true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:subject"),
                        position:           3,
                        repeatable:         true,
                        required:           true)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:creator"),
                        position:           4,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor"),
                        position:           5,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:abstract"),
                        position:           6,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:coverage:spatial"),
                        position:           7,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:type:genre"),
                        position:           8,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:language"),
                        position:           9,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier:bibliographicCitation"),
                        position:           10,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:publisher"),
                        position:           11,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:relation:ispartof"),
                        position:           12,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:description:sponsorship"),
                        position:           13,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:rights"),
                        position:           14,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:identifier"),
                        position:           15,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:name"),
                        position:           16,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:level"),
                        position:           17,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:committeeChair"),
                        position:           18,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:contributor:advisor"),
                        position:           19,
                        repeatable:         true,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:grantor"),
                        position:           20,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:discipline"),
                        position:           21,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:department"),
                        position:           22,
                        repeatable:         false,
                        required:           false)
    self.elements.build(registered_element: RegisteredElement.find_by_name("thesis:degree:program"),
                        position:           23,
                        repeatable:         false,
                        required:           false)
    self.save!
  end

  def breadcrumb_label
    name
  end

  ##
  # Overrides parent to intelligently clone an instance including all of its
  # elements.
  #
  # @return [SubmissionProfile]
  #
  def dup
    clone = super
    clone.name = "Clone of #{self.name}"
    clone.default = false
    # The instance requires an ID for SubmissionProfileElement validations.
    clone.save!
    self.elements.each { |e| clone.elements << e.dup }
    clone
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
