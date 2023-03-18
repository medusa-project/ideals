##
# Defines an ordered list of {RegisteredElement metadata elements}, their
# labels, and whether they are required, repeatable, etc., for the purposes of
# submitting an item.
#
# One instance is marked as the default per institution, and is used by all
# submitters across all {Collection}s, but this can be overridden by assigning
# other profiles to specific collections. Collections without an assigned
# profile will use the {SubmissionProfile#institution_default institution's
# default profile}.
#
# The elements specified in a submission profile are a snapshot of the same
# institution's {RegisteredElement element registry} at the time of its
# creation.
#
# A submission profile can be thought of as the "input" counterpart to a
# {MetadataProfile}, which is used for "output." It tells the system what
# inputs to supply to users during the item submission workflow.
#
# # Attributes
#
# * `created_at`          Managed by ActiveRecord.
# * `name`                The name of the submission profile. Must be unique
#                         within the same institution.
# * `institution_default` Whether the submission profile is used by
#                         {Collection}s without a submission profile assigned,
#                         or in cross-collection contexts. (Only one submission
#                         profile can be marked as such per institution--this
#                         is enforced by an `after_save` callback.)
# * `updated_at`          Managed by ActiveRecord.
#
class SubmissionProfile < ApplicationRecord
  include Breadcrumb

  belongs_to :institution

  has_many :collections, inverse_of: :submission_profile
  has_many :elements, -> { order(:position) },
           class_name: "SubmissionProfileElement",
           inverse_of: :submission_profile
  validates :name, presence: true, length: { minimum: 2 }

  after_save :ensure_default_uniqueness

  ##
  # Ascribes system-required {SubmissionProfileElement}s to a newly created
  # instance.
  #
  def add_required_elements
    self_reg_e_ids = self.elements.map(&:registered_element_id)
    self.institution.required_elements.
      reject{ |e| self_reg_e_ids.include?(e.id) }.
      sort_by(&:label).
      each_with_index do |reg_e, index|
      self.elements.build(registered_element: reg_e,
                          position:           index,
                          repeatable:         false,
                          required:           true).save!
    end
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
    clone                     = super
    clone.name                = "Clone of #{self.name}"
    clone.institution_default = false
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
    if self.institution_default
      self.class.all.
        where(institution_id: self.institution_id).
        where('id != ?', self.id).each do |instance|
        instance.update!(institution_default: false)
      end
    end
  end

end
