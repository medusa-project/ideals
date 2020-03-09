# frozen_string_literal: true

##
# A collection is a container for {Item}s.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `metadata_profile_id`   Foreign key to {MetadataProfile}. Instances without
#                           this set should use the {MetadataProfile#default
#                           default profile}. In most cases,
#                           {effective_metadata_profile} should be used instead
#                           of accessing this directly.
# * `primary_unit_id`       Foreign key to {Unit}.
# * `submission_profile_id` Foreign key to {SubmissionProfile}. Instances
#                           without this set should use the
#                           {SubmissionProfile#default default profile}. In
#                           most cases, {effective_submission_profile} should
#                           be used instead of accessing this directly.
# * `updated_at`            Managed by ActiveRecord.
#
# # Relationships
#
# * `elements`            References zero-to-many {AscribedElement}s used to
#                         describe an instance.
# * `items`               References all {Items} contained within the instance.
# * `managers`            References the {Manager}s that are allowed to manage
#                         the instance. This does not include all "effective"
#                         managers, such as administrators of owning units or
#                         system administrators; see
#                         {User#effective_manager()?}.
# * `managing_users`      More useful alternative to {managers} that returns
#                         {User}s instead.
# * `metadata_profile`    References the {MetadataProfile} directly assigned
#                         to the instance, if any (see the documentation of the
#                         `metadata_profile_id` attribute).
# * `primary_unit`        References the primary {Unit} in which the instance
#                         resides.
# * `submission_profile`  References the {SubmissionProfile} directly assigned
#                         to the instance, if any (see the documentation of the
#                         `submission_profile_id` attribute).
# * `submissions`         References all {Submissions} into the instance.
# * `submitters`          References all {Submitter}s who are allowed to submit
#                         {Item}s to the instance.
# * `submitting_users`    More useful alternative to {submitters} that returns
#                         {User}s instead.
# * `units`               References all units to which the instance is
#                         directly assigned. See also {all_units}.
#
class Collection < ApplicationRecord
  include Breadcrumb
  include Describable
  include Indexed

  class IndexFields
    CLASS         = ElasticsearchIndex::StandardFields::CLASS
    CREATED       = ElasticsearchIndex::StandardFields::CREATED
    ID            = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED  = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    MANAGERS      = "i_manager_id"
    PRIMARY_UNIT  = "i_primary_unit_id"
    SUBMITTERS    = "i_submitter_id"
    UNIT_TITLES   = "s_unit_titles"
    UNITS         = "i_units"
  end

  has_many :elements, class_name: "AscribedElement"
  has_and_belongs_to_many :items
  belongs_to :metadata_profile, inverse_of: :collections, optional: true
  belongs_to :primary_unit, class_name: "Unit",
             foreign_key: "primary_unit_id", optional: true
  has_many :managers
  has_many :managing_users, through: :managers,
           class_name: "User", source: :user
  belongs_to :submission_profile, inverse_of: :collections, optional: true
  has_many :submitters
  has_many :submitting_users, through: :submitters,
           class_name: "User", source: :user
  # N.B.: this association includes only directly associated units--not any of
  # their parents or children--and it also doesn't include the primary unit.
  # See {all_units} and {primary_unit}.
  has_and_belongs_to_many :units

  breadcrumbs parent: :primary_unit, label: :title

  ##
  # @return [Enumerable<Unit>] All directly associated units, as well as all of
  #         those units' parents, in undefined order.
  #
  def all_units
    bucket = Set.new
    bucket << self.primary_unit if self.primary_unit_id
    units.each do |unit|
      bucket << unit
      bucket += unit.all_parents
    end
    bucket
  end

  ##
  # @return [Enumerable<User>]
  #
  def all_unit_administrators
    bucket = Set.new
    all_units.each do |unit|
      bucket += unit.all_administrators
    end
    bucket
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]         = self.class.to_s
    doc[IndexFields::CREATED]       = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]  = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::MANAGERS]      = self.managers.pluck(:user_id)
    doc[IndexFields::PRIMARY_UNIT]  = self.primary_unit_id
    doc[IndexFields::SUBMITTERS]    = self.submitters.pluck(:user_id)
    doc[IndexFields::UNIT_TITLES]   = self.all_units.map(&:title)
    doc[IndexFields::UNITS]         = self.unit_ids

    # Index ascribed metadata elements into dynamic fields.
    self.elements.each do |element|
      field = element.registered_element.indexed_name
      unless doc[field]&.respond_to?(:each)
        doc[field] = []
      end
      doc[field] << element.string[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  ##
  # @return [MetadataProfile] The metadata profile assigned to the instance, or
  #         the default profile if no profile is assigned.
  #
  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  ##
  # @return [SubmissionProfile] The submission profile assigned to the
  #         instance, or the default profile if no profile is assigned.
  #
  def effective_submission_profile
    self.submission_profile || SubmissionProfile.default
  end

  def label
    title
  end

end
