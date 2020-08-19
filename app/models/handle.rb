# frozen_string_literal: true

# Represents a handle in the handle server.
#
# The local database is the source-of-truth for handles.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `prefix`     Handle prefix. This is sourced from the configuration and
#                should not be set manually.
# * `suffix`     Portion of the handle following the prefix. This is an auto-
#                incrementing value and should not be set manually.
# * `updated_at` Managed by ActiveRecord.
#
# # Relationships
#
# * `collection` References an owning {Collection}.
# * `item`       References an owning {Item}.
# * `unit`       References an owning {Unit}.
#
class Handle < ApplicationRecord

  belongs_to :unit, optional: true
  belongs_to :collection, optional: true
  belongs_to :item, optional: true

  before_save :assign_prefix, if: -> { self.prefix.blank? }
  after_save :put_to_server, if: -> { !self.transient &&
      self.prefix == ::Configuration.instance.handles[:prefix] && !ENV['CI'] == '1' }
  after_destroy :delete_from_server, unless: -> { self.transient && !ENV['CI'] == '1' }

  validate :validate_entity_association

  # For testing
  attr_accessor :transient

  ##
  # @param value [Integer]
  #
  def self.set_suffix_start(value)
    ActiveRecord::Base.connection.execute(
        "ALTER SEQUENCE handles_suffix_seq RESTART WITH #{value};")
  end

  ##
  # @return [void]
  #
  def delete_from_server
    HandleClient.new.delete_handle(self.handle)
  end

  ##
  # @return [Boolean]
  #
  def exists_on_server?
    HandleClient.new.exists?(self.handle)
  end

  ##
  # @return [String] Full handle.
  #
  def handle
    config = ::Configuration.instance
    prefix = config.handles[:prefix]
    "#{prefix}/#{suffix}"
  end

  ##
  # Saves the instance to the handle server. If the handle does not already
  # exist on the handle server, it is created; otherwise it is updated.
  #
  # @return [void]
  # @raises [RuntimeError] if the instance's prefix is not supported by the
  #         handle server.
  #
  def put_to_server
    config = ::Configuration.instance
    base_url = config.website[:base_url]
    helpers  = Rails.application.routes.url_helpers
    if self.unit
      entity_url = helpers.unit_url(self.unit, host: base_url)
    elsif self.collection
      entity_url = helpers.collection_url(self.collection, host: base_url)
    elsif self.item
      entity_url = helpers.item_url(self.item, host: base_url)
    else
      raise "No entity association"
    end
    HandleClient.new.create_url_handle(handle: self.handle, url: entity_url)
  end

  def to_s
    self.handle
  end

  def url
    sprintf("%s/%s",
            ::Configuration.instance.handles[:base_url],
            self.handle)
  end

  private

  def assign_prefix
    if self.prefix.blank?
      self.prefix = ::Configuration.instance.handles[:prefix]
    end
  end

  ##
  # Ensures that the instance is associated with one and only one entity.
  #
  def validate_entity_association
    ids = [self.unit_id, self.collection_id, self.item_id].reject(&:nil?).length
    if ids > 1
      errors.add(:base, "Instance can be associated with only one entity")
    elsif ids == 0
      errors.add(:base, "Instance must be associated with an entity")
    end
  end

end
