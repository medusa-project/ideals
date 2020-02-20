# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `discoverable`          If false, the submitter has indicated during
#                           submission that the item should be private, which
#                           means it should not be included in search results,
#                           and its metadata should not be available except to
#                           administrators.
# * `in_archive`            Like a published state, sort of, but can be
#                           overridden by `discoverable`. If false, it means
#                           the item is currently in the submission process (a
#                           draft) or has been withdrawn.
# * `primary_collection_id` Foreign key to {Collection}.
# * `submitter_id`          Foreign key to {User}.
# * `updated_at`            Managed by ActiveRecord.
# * `withdrawn`             An administrator has made the item inaccessible,
#                           but not totally deleted it. Requests for
#                           withdrawn items return HTTP 410 Gone.
#
# # Relationships
#
# * `bitstreams`         References all associated {Bitstream}s.
# * `collections`        References all owning {Collections}.
# * `elements`           References zero-to-many {AscribedElement}s used to
#                        describe an instance.
# * `primary_collection` References the primary {Collection} in which the
#                        instance resides.
#
class Item < ApplicationRecord
  include Breadcrumb
  include Describable
  include Indexed

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    CLASS              = ElasticsearchIndex::StandardFields::CLASS
    COLLECTIONS        = "i_collection_ids"
    CREATED            = ElasticsearchIndex::StandardFields::CREATED
    DISCOVERABLE       = "b_discoverable"
    ID                 = ElasticsearchIndex::StandardFields::ID
    IN_ARCHIVE         = "b_in_archive"
    LAST_INDEXED       = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PRIMARY_COLLECTION = "i_primary_collection_id"
    PRIMARY_UNIT       = "i_primary_unit_id"
    SUBMITTER          = "i_submitter_id"
    WITHDRAWN          = "b_withdrawn"
  end

  has_many :bitstreams
  has_and_belongs_to_many :collections
  has_many :elements, class_name: "AscribedElement"
  belongs_to :primary_collection, class_name: "Collection",
             foreign_key: "primary_collection_id", optional: true
  belongs_to :submitter, class_name: "User", inverse_of: "submitted_items",
             optional: true

  breadcrumbs parent: :primary_collection, label: :title

  ##
  # @return [Enumerable<Collection>] All owning collections, including the
  #                                  primary one.
  #
  def all_collections
    bucket = Set.new
    bucket << self.primary_collection if self.primary_collection_id
    collections.each do |collection|
      bucket << collection
    end
    bucket
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]              = self.class.to_s
    doc[IndexFields::COLLECTIONS]        = self.all_collections.map(&:id)
    doc[IndexFields::CREATED]            = self.created_at.utc.iso8601
    doc[IndexFields::DISCOVERABLE]       = self.discoverable
    doc[IndexFields::IN_ARCHIVE]         = self.in_archive
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection_id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc[IndexFields::SUBMITTER]          = self.submitter_id
    doc[IndexFields::WITHDRAWN]          = self.withdrawn

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
  # @return [MetadataProfile] The primary collection's metadata profile, or the
  #                           {MetadataProfile#default default profile} if not
  #                           set.
  #
  def effective_metadata_profile
    self.primary_collection&.effective_metadata_profile || MetadataProfile.default
  end

  def label
    title
  end

  ##
  # @return [MetadataProfile] Effective metadata profile of the primary
  #                           {Collection}.
  #
  def metadata_profile
    primary_collection.effective_metadata_profile
  end

  ##
  # @return [Unit]
  #
  def primary_unit
    #noinspection RubyYardReturnMatch
    self.primary_collection&.primary_unit
  end

end
