class Bitstream < ApplicationRecord
  belongs_to :item

  validates :key, presence: { allow_blank: false }, uniqueness: true
  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
end
