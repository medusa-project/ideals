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

end
