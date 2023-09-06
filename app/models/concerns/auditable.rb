# frozen_string_literal: true

##
# Module to be included by models that associate with {Event}s for the purpose
# of event and change tracking.
#
# Auditable models should usually be created, updated and, deleted via the
# {Command} classes.
#
module Auditable
  extend ActiveSupport::Concern

  ##
  # This implementation includes direct model properties. Including classes
  # should override and add their own relevant properties to the instance
  # returned from `super`. Association keys should be in the format
  # `association:property` or similar, keeping in mind that all keys must be
  # unique.
  #
  # @return [Hash] Hash of properties (including association properties)
  #                relevant to change tracking, in a flat key-value format.
  #
  def as_change_hash
    hash       = {}
    omit_attrs = %w(id created_at updated_at) # filter out the noise
    self.attributes.reject{ |k, v| omit_attrs.include?(k) }.each do |attr|
      hash[attr[0]] = attr[1]
    end
    hash
  end

  ##
  # Shortcut to accessing the {Event::Type::CREATE create-type event} ascribed
  # to the instance when it was created.
  #
  # @return [Event]
  #
  def create_event
    self.events.
      where(event_type: Event::Type::CREATE).
      order(:happened_at).
      limit(1).
      first
  end

  ##
  # Shortcut to accessing the last {Event::Type::UPDATE update-type event}
  # ascribed to the instance.
  #
  # @return [Event]
  #
  def last_update_event
    self.events.
      where(event_type: Event::Type::UPDATE).
      order(happened_at: :desc).
      limit(1).
      first
  end

end
