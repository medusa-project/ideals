##
# Item submission.
#
class Submission < ApplicationRecord
  belongs_to :collection, inverse_of: :submissions, optional: true
  belongs_to :user, inverse_of: :submissions
end
