# frozen_string_literal: true

##
# # Attributes
#
# * `created_at`                 Managed by ActiveRecord.
# * `deposit_agreement_question` Foreign key to {DepositAgreementQuestion}.
# * `position`                   Order of the response within the question.
# * `success`                    Whether the response is acceptable with
#                                regards to advancing the deposit/submission.
# * `text`                       Text of the question.
# * `updated_at`                 Managed by ActiveRecord.
#
class DepositAgreementQuestionResponse < ApplicationRecord

  belongs_to :deposit_agreement_question

  validates_presence_of :text

  self.implicit_order_column = "position"

end
