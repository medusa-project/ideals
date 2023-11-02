# frozen_string_literal: true

##
# Email address pattern associated with a [UserGroup]. All [User]s whose email
# address matches an instance will be considered to be included in the group.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `pattern`    Email address pattern. Not controlled/unique. This may be a
#                literal substring or a regex, in which case it is surrounded
#                by slashes.
# * `updated_at` Managed by ActiveRecord.
#
class EmailPattern < ApplicationRecord

  belongs_to :user_group

  validates :pattern, presence: true

  ##
  # @param email [String] Email address.
  # @return [Boolean]
  #
  def matches?(email)
    if self.pattern.start_with?("/") && self.pattern.end_with?("/")
      email.match?(Regexp.new(self.pattern[1..-2]))
    else
      email.include?(self.pattern)
    end
  end

  def to_s
    pattern
  end

end

