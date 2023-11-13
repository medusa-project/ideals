require "test_helper"

class PrebuiltSearchElementTest < ActiveSupport::TestCase

  setup do
    @instance = prebuilt_search_elements(:southwest_cats_title)
    assert @instance.valid?
  end

  # prebuilt_search

  test "prebuilt_search is required" do
    @instance.prebuilt_search = nil
    assert !@instance.valid?
  end

  # registered_element

  test "registered_element is required" do
    @instance.registered_element = nil
    assert !@instance.valid?
  end

  # term

  test "term is required" do
    @instance.term = nil
    assert !@instance.valid?
  end

  test "term is normalized" do
    @instance.term = " test  test "
    assert_equal "test test", @instance.term
  end

end
