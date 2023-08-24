##
# Attachment of a {RegisteredElement} to a {Describable} resource.
#
# N.B.: Because it is so common to access multiple elements ascribed to the
# same entity during a single request, which can cause n+1 queries, it is
# usually very beneficial for performance to call `includes(:elements)` on an
# {ActiveRecord::Relation} before accessing the results.
#
# # Attributes
#
# * `created_at`:            Managed by ActiveRecord.
# * `item_id`:               ID of the associated {Item}. Set only if
#                            {collection_id} is not set.
# * `position`               Position relative to other {AscribedElement}s
#                            **with the same name** attached to the same
#                            resource. The counting starts at 1.
# * `registered_element_id`: ID of the associated {RegisteredElement}. Note
#                            that its owning institution must be the same as
#                            that of the associated {Item}.
# * `string`:                String value. Note that this may contain a date,
#                            which, when received from the submission form, is
#                            in `Month DD, YYYY` format.
# * `updated_at`:            Managed by ActiveRecord.
# * `uri`:                   Linked Data URI value.
#
class AscribedElement < ApplicationRecord

  belongs_to :registered_element
  belongs_to :item

  validates :string, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 1 },
            allow_blank: false

  validate :registered_element_and_item_are_of_same_institution

  ##
  # Generates a two-column report with distinct element value (string) in the
  # first column and number of uses of string by items in the second column, in
  # descending order by the second column.
  #
  # @param element [RegisteredElement]
  # @return [Enumerable<Hash<String,Integer>>]
  #
  def self.usage_frequencies(element)
    sql = "SELECT ae.string AS string, COUNT(i.id) AS item_count
      FROM ascribed_elements ae
      LEFT JOIN items i ON ae.item_id = i.id
      LEFT JOIN registered_elements re ON ae.registered_element_id = re.id
      WHERE re.id = #{element.id}
      GROUP BY string
      ORDER BY item_count DESC, string ASC;"
    ActiveRecord::Base.connection.exec_query(sql)
  end

  ##
  # @return [Date, nil] Instance corresponding to the string value if it can be
  #                     parsed; otherwise `nil`.
  #
  def date
    s = self.string
    return nil if s.blank?
    # ISO 8601
    if s.match?(/\dT\d{2}:/)
      return Date.parse(s)
    # MM/DD/YY or MM/DD/YYYY
    elsif s.match?(/\A\d{1,2}\/\d{1,2}\/\d{2,4}/)
      parts = s.split("/")
      parts[2] = "19#{parts[2]}" if parts[2].length == 2
      return Date.new(parts[2].to_i, parts[0].to_i, parts[1].to_i)
    # YYYY-MM-DD
    elsif s.match?(/\A\d{4}-\d{2}-\d{2}/)
      parts = s.split("-")
      return Date.new(parts[0].to_i, parts[1].to_i, parts[2].to_i)
    # YYYY-MM
    elsif s.match?(/\A\d{4}-\d{2}/)
      parts = s.split("-")
      return Date.new(parts[0].to_i, parts[1].to_i)
    # YYYY
    elsif s.match?(/\A\d{4}/)
      return Date.new(s.to_i)
    # Mon DD YYYY, DD-Mon-YY, Mon YYYY
    elsif s.match?(/[A-Za-z]+ \d{1,2},? \d{4}/) ||
      s.match?(/\d{2}-[A-Za-z]+-\d{2}/) ||
      s.match?(/[A-Za-z]+ \d{4}/)
      return Date.parse(s)
    end
    nil
  rescue # maybe a DateError, ArgumentError...
    nil
  end

  ##
  # @return [String] Label of the associated {RegisteredElement}.
  #
  def label
    registered_element&.label
  end

  ##
  # @return [String] Name of the associated {RegisteredElement}.
  #
  def name
    registered_element&.name
  end

  ##
  # @return [Hash<Symbol,String>,nil] Hash with `:family_name` and `:given_name`
  #                                   keys, or `nil` if {string} does not
  #                                   appear to contain a person name.
  #
  def person_name
    parts = self.string&.split(",") || []
    if parts.length >= 2
      return {
        family_name: parts[0].strip,
        given_name:  parts[1..].join(",").strip
      }
    end
    nil
  end


  private

  def registered_element_and_item_are_of_same_institution
    # Occasionally--during the submission process in particular--an item may
    # not be associated with a collection before metadata is ascribed.
    ins   = self.item.institution
    reg_e = self.registered_element
    if ins && reg_e && ins.id != reg_e.institution_id
      errors.add(:base, "Registered element and item must be of the same institution")
      throw(:abort)
    end
  end

end
