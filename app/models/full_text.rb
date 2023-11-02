# frozen_string_literal: true

##
# Encapsulates a {Bitstream}'s full text. This is a separate model in order to
# conserve memory when loading {Bitstream}s via ActiveRecord. Instances' text
# tends to be pretty small, but a few are many megabytes, and a few of those
# are hundreds of megabytes, believe it or not.
#
# Full text is included in {Item} documents, making it searchable. This is
# currently all it is used for--it isn't displayed anywhere, publicly or
# privately.
#
# # Attributes
#
# * `bitstream_id` Foreign key to {Bitstream}.
# * `created_at`   Managed by ActiveRecord.
# * `text`         Text string, generally extracted from the contents of e.g.
#                  PDF- or text-type bitstreams.
# * `updated_at`   Managed by ActiveRecord.
#
class FullText < ApplicationRecord

  belongs_to :bitstream

  validates_presence_of :text

  def to_s
    text.present? ? text : super
  end

end