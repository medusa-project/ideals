# frozen_string_literal: true

##
# Encapsulates the ability of a {UserGroup} to access the {Bitstream}s of an
# {Item}.
#
class BitstreamAuthorization < ApplicationRecord

  belongs_to :item
  belongs_to :user_group

end
