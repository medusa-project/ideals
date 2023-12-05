# frozen_string_literal: true

##
# Relates a {User} to a {Collection} indicating that the user has permission to
# submit to it.
#
# # Attributes
#
# * `collection_id` Foreign key to {Collection}.
# * `created_at`    Managed by ActiveRecord.
# * `user_id`       Foreign key to {User}.
# * `updated_at`    Managed by ActiveRecord.
#
class SubmittableCollection < ApplicationRecord

  belongs_to :user
  belongs_to :collection

end
