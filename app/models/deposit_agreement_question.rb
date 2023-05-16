# frozen_string_literal: true

##
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `help_text`  Help text.
# * `position`   Order of the question within the deposit form.
# * `text`       Text of the question.
# * `updated_at` Managed by ActiveRecord.
#
class DepositAgreementQuestion < ApplicationRecord

  belongs_to :institution
  has_many :responses, class_name: "DepositAgreementQuestionResponse"

  validates_presence_of :text

  self.implicit_order_column = "position"

end
