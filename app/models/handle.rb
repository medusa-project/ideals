# frozen_string_literal: true

class Handle < ApplicationRecord
  def klass_name
    ResourceType::HASH[resource_type_id]
  end

  def resource
    resource_klass = klass_name.classify.safe_constantize
    resource_klass.find(resource_id)
  end
end
