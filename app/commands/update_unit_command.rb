# frozen_string_literal: true

class UpdateUnitCommand < Command

  ##
  # @param user [User]
  # @param unit [Unit]
  # @param description [String]
  #
  def initialize(user:, unit:, description: nil)
    @user           = user
    @unit           = unit
    @before_changes = unit.as_change_hash
    @description    = description
  end

  def execute(&block)
    yield(@unit)
    Event.create!(event_type:     Event::Type::UPDATE,
                  institution:    @unit.institution,
                  unit:           @unit,
                  user:           @user,
                  before_changes: @before_changes,
                  after_changes:  @unit.as_change_hash,
                  description:    @description)
  end

end