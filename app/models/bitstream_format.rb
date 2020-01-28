class BitstreamFormat < ApplicationRecord

  has_many :bitstreams

  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: false
  validates_uniqueness_of :media_type

  validates_presence_of :description, :short_description

end
