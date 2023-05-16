require "test_helper"

class DepositAgreementQuestionTest < ActiveSupport::TestCase

  setup do
    @instance = deposit_agreement_questions(:southwest_one)
    assert @instance.valid?
  end

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  test "text is required" do
    @instance.text = ""
    assert !@instance.valid?
  end

end
