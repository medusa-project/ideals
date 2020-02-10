# frozen_string_literal: true

##
# A collection is a container for {Item}s.
#
# # Relationships
#
# Collections have many-to-many relationships with {Item}s and {Unit}s.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
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

  def label
    title
  end

end
