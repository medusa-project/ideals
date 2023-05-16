require "test_helper"

class DepositAgreementQuestionResponseTest < ActiveSupport::TestCase

  setup do
    @instance = deposit_agreement_question_responses(:southwest_q1_one)
    assert @instance.valid?
  end

  test "deposit_agreement_question is required" do
    @instance.deposit_agreement_question = nil
    assert !@instance.valid?
  end

  test "text is required" do
    @instance.text = ""
    assert !@instance.valid?
  end

end
