# frozen_string_literal: true

# Represents a handle in the handle server.
#
# The local database is the source-of-truth for handles.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
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

  after_create :put_to_server, unless: -> { self.transient }
  after_destroy :delete_from_server, unless: -> { self.transient }

  validate :validate_entity_association

  # For testing
  attr_accessor :transient

  ##
  # @return [String]
  #
  def self.prefix
    ::Configuration.instance.handles[:prefix]
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
    "#{prefix}/#{suffix}"
  end

  ##
  # @return [Institution]
  #
  def institution
    self.unit&.institution || self.collection&.institution || self.item&.institution
  end

  ##
  # Permanent URL. In production, this will be a Global Handle Registry
  # (`hdl.handle.net`) URL. Elsewhere, it may use the hostname of the handle
  # server (which may not be registered with the GHR).
  #
  # @see url
  #
  def permanent_url
    config = ::Configuration.instance
    host   = config.handles[:use_ghr] ?
               "https://hdl.handle.net" : config.handles[:base_url].chomp("/")
    [host, self.handle].join("/")
  end

  ##
  # @return [String]
  #
  def prefix
    self.class.prefix
  end

  ##
  # Saves the instance to the handle server. If the handle does not already
  # exist on the handle server, it is created; otherwise it is updated.
  #
  # @return [void]
  # @raises [RuntimeError] if the instance's prefix is not supported by the
  #                        handle server.
  #
  def put_to_server
    self.reload # the prefix is auto-incrementing
    base_url = self.institution&.scope_url
    return unless base_url
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

  ##
  # URL of the handle on the local handle server.
  #
  # @see permanent_url
  #
  def url
    sprintf("%s/%s",
            ::Configuration.instance.handles[:base_url],
            self.handle)
  end


  private

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
