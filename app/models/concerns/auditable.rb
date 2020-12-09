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

end
