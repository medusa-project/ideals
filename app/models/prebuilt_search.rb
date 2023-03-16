class PrebuiltSearch < ApplicationRecord

  include Breadcrumb

  class OrderingDirection
    ASCENDING  = 0
    DESCENDING = 1

    def self.all
      OrderingDirection.constants.map{ |c| OrderingDirection::const_get(c) }
    end

    ##
    # @param value [Integer] One of the constant values.
    # @return [String] English label for the value.
    #
    def self.label(value)
      label = OrderingDirection.constants
                  .find{ |c| OrderingDirection.const_get(c) == value }
                  .to_s
                  .split("_")
                  .map(&:capitalize)
                  .join(" ")
      if label.present?
        return label
      else
        raise ArgumentError, "No ordering direction with value #{value}"
      end
    end
  end

  belongs_to :institution
  belongs_to :ordering_element, class_name: "RegisteredElement", optional: true

  validates :name, presence: true
  validate :validate_ordering_element_institution

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    PrebuiltSearch
  end

  ##
  # @return [String]
  #
  def url_query
    pairs = []
    if self.ordering_element
      pairs << ["sort", self.ordering_element.indexed_field]
      case self.direction
      when PrebuiltSearch::OrderingDirection::ASCENDING
        pairs << ["direction", "asc"]
      when PrebuiltSearch::OrderingDirection::DESCENDING
        pairs << ["direction", "desc"]
      end
    end
    "?" + pairs.map{ |p| p.map{ |a| StringUtils.url_encode(a) }.join("=") }.join("&")
  end


  private

  ##
  # Ensures that {ordering_element} is in the same institution as the instance.
  #
  def validate_ordering_element_institution
    if self.ordering_element && self.ordering_element.institution != self.institution
      errors.add(:ordering_element, "must be in the same institution")
      throw(:abort)
    end
  end

end
