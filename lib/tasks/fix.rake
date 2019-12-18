# frozen_string_literal: true

namespace :fix do
  desc "update resource type from collection group to unit"
  task update_resource_type: :environment do
    Handle.all.each do |handle|
      handle.update_attribute(resource_type, "Unit") if handle.resource_type == "CollectionGroup"
    end
  end
end
