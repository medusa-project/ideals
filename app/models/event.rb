##
# Encapsulates some kind of event, characterized by one of the {Event#Type}
# constant values. Records information like the triggering user, the model
# object to which the event relates, and timestamp information.
#
# # Attributes
#
# * `after_changes`  JSON serialization of the associated {Item} after changes.
# * `before_changes` JSON serialization of the associated {Item} after changes.
# * `bitstream_id`   References the {Bitstream} to which the instance relates
#                    (optional).
# * `created_at`     Managed by ActiveRecord.
# * `description`    English description of the event in past tense.
# * `event_type`     One of the {Event::Type} constant values.
# * `item_id`        References the {Item} to which the instance relates
#                    (optional).
# * `updated_at`     Managed by ActiveRecord.
# * `user_id`        References the {User} who triggered the event. This may be
#                    nil if the event was triggered by e.g. an automated
#                    process.
#
class Event < ApplicationRecord

  ##
  # Contains constant values for assignment to the {event_type} attribute.
  #
  class Type
    CREATE   = 0
    DELETE   = 1
    UPDATE   = 2
    DOWNLOAD = 3

    def self.all
      Event::Type.constants.map{ |c| Event::Type::const_get(c) }
    end

    ##
    # @param value [Integer] One of the constant values.
    # @return [String] English label for the value.
    #
    def self.label(value)
      label = Type.constants
                    .find{ |c| Type.const_get(c) == value }
                    .to_s
                    .split("_")
                    .map(&:capitalize)
                    .join(" ")
      if label.present?
        return label
      else
        raise ArgumentError, "No type with value #{value}"
      end
    end
  end

  belongs_to :bitstream, optional: true
  belongs_to :item, optional: true
  belongs_to :user, optional: true

  validates :event_type, inclusion: { in: Type.all }
  validate :validate_changes
  validate :validate_associated_object

  ##
  # @return [Event] The first created event.
  #
  def self.first
    Event.all.order(:created_at).limit(1).first
  end

  def after_changes
    json = read_attribute(:after_changes)
    json ? JSON.parse(json) : nil
  end

  ##
  # @param auditable [Auditable,Hash]
  #
  def after_changes=(auditable)
    hash = auditable.kind_of?(Auditable) ? auditable.as_change_hash : auditable
    write_attribute(:after_changes, JSON.generate(hash))
  end

  def before_changes
    json = read_attribute(:before_changes)
    json ? JSON.parse(json) : nil
  end

  ##
  # @param auditable [Auditable,Hash]
  #
  def before_changes=(auditable)
    hash = auditable.kind_of?(Auditable) ? auditable.as_change_hash : auditable
    write_attribute(:before_changes, JSON.generate(hash))
  end

  private

  ##
  # Ensures that the instance is associated with an object.
  #
  def validate_associated_object
    if bitstream_id.nil? && item_id.nil?
      errors.add(:base, "is not associated with an entity")
    end
  end

  ##
  # Ensures that {before_changes} and {after_changes} contain valid JSON.
  #
  def validate_changes
    [:before_changes, :after_changes].each do |attr_name|
      attr = read_attribute(attr_name)
      if attr.present?
        begin
          JSON.parse(attr)
        rescue JSON::ParserError => e
          errors.add(attr_name, "#{e}")
        end
      end
    end
  end

end
