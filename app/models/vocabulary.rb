# frozen_string_literal: true

##
# Controlled vocabulary associated with a {RegisteredElement}.
#
# When {RegisteredElement}s are associated with a vocabulary, their
# {RegisteredElement#input_type input type} is overridden as a select menu,
# which appears in the submission interface and advanced search form, among
# potentially other places.
#
# # Attributes
#
# * `created_at`     Managed by ActiveRecord.
# * `institution_id` Foreign key to the owning {Institution}.
# * `name`           Name of the vocabulary.
# * `updated_at`     Managed by ActiveRecord.
#
class Vocabulary < ApplicationRecord

  include Breadcrumb

  belongs_to :institution
  has_many :registered_elements
  has_many :vocabulary_terms

  # uniqueness (within an institution) enforced by database constraints
  validates :name, presence: true

  def breadcrumb_label
    self.name
  end

  def breadcrumb_parent
    Vocabulary
  end

  ##
  # N.B. the CSV format is two columns (displayed value and stored value) with
  # a header row.
  #
  # @param pathname [String] CSV pathname. Used when `csv` is not provided.
  # @param csv [String]      CSV string. Used when `pathname` is not provided.
  # @param task [Task]       Optional.
  #
  def import_terms_from_csv(pathname: nil, csv: nil, task: nil)
    # Read once to get a row count for calculating progress.
    num_rows = 0
    if pathname
      File.open(pathname, "r") do |file|
        csv      = CSV.new(file)
        csv.each { num_rows += 1 }
      end
    else
      num_rows = csv.lines.count
    end
    num_rows -= 1 # subtract header row

    # Work inside a transaction to avoid an incomplete import.
    Vocabulary.transaction do
      if pathname
        File.open(pathname, "r") do |file|
          csv = CSV.new(file)
          csv.each_with_index do |row, row_index|
            import_term_from_csv(row, row_index, num_rows, task)
          end
        end
      else
        rows = CSV.parse(csv)
        rows.each_with_index do |row, row_index|
          import_term_from_csv(row, row_index, num_rows, task)
        end
      end
    end
  end


  private

  def import_term_from_csv(row, row_index, num_rows, task)
    return if row_index == 0                 # skip the header row
    return if row[0].blank? && row[1].blank? # if one is blank but the other isn't, we want to error out
    term = self.vocabulary_terms.
      where("displayed_value = ? OR stored_value = ?", row[0], row[1]).
      limit(1).first
    if term
      term.update!(displayed_value: row[0],
                   stored_value:    row[1])
    else
      self.vocabulary_terms.build(displayed_value: row[0],
                                  stored_value:    row[1]).save!
    end
    if row_index % 100 == 0
      task&.progress(row_index / num_rows.to_f,
                     status_text: "Importing vocabulary terms into #{self.name}")
    end
  end

end
