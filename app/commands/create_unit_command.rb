# frozen_string_literal: true

class CreateUnitCommand < Command

  ##
  # @param user [User] User performing the command.
  # @param unit [Unit] New instance, already initialized and ready to save.
  #
  def initialize(user:, unit:)
    @user = user
    @unit = unit
  end

  def execute
    Unit.transaction do
      @unit.save!
      Event.create!(event_type:    Event::Type::CREATE,
                    institution:   @unit.institution,
                    unit:          @unit,
                    user:          @user,
                    after_changes: @unit.as_change_hash)
    end
  end

end