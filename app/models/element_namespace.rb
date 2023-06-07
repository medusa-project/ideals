# frozen_string_literal: true
#
# When a {RegisteredElement} name is in `prefix:name` format, this class maps
# the prefix to a URI for use in XML and linked data. Institutions may
# customize their own element namespaces, which must be unique among an
# institution.
#
# # Attributes
#
# * `created_at`     Managed by ActiveRecord.
# * `institution_id` Foreign key to the owning {Institution}.
# * `prefix`         Element prefix--for example, the prefix of a `dc:title`
#                    element would be `dc`.
# * `updated_at`     Managed by ActiveRecord.
# * `uri`            URI string.
#
class ElementNamespace < ApplicationRecord

  belongs_to :institution

  validates_presence_of :prefix
  validates_presence_of :uri

  def to_s
    prefix
  end

end
