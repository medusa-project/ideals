# frozen_string_literal: true

##
# Represents an "index page" accessible from the header browse menu. An index
# page displays lists of {AscribedElement} values corresponding to one or more
# of an institution's {RegisteredElement}s.
#
# # Attributes
#
# * `created_at`     Managed by ActiveRecord.
# * `institution_id` Foreign key to {Institution}.
# * `name`           Name of the page.
# * `updated_at`     Managed by ActiveRecord.
#
class IndexPage < ApplicationRecord

  include Breadcrumb

  belongs_to :institution
  has_and_belongs_to_many :registered_elements

  validates :name, presence: true

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    IndexPage
  end

end
