require "test_helper"

class ElementNamespaceTest < ActiveSupport::TestCase

  setup do
    @instance = element_namespaces(:southwest_dc)
    assert @instance.valid?
  end

  # institution

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  # prefix

  test "prefix is required" do
    @instance.prefix = nil
    assert !@instance.valid?
    @instance.prefix = ""
    assert !@instance.valid?
  end

  test "prefix is normalized" do
    @instance.prefix = " test  test "
    assert_equal "test test", @instance.prefix
  end

  # to_s()

  test "to_s() returns the prefix" do
    assert_equal @instance.prefix, @instance.to_s
  end

  # uri

  test "uri is required" do
    @instance.uri = nil
    assert !@instance.valid?
    @instance.uri = ""
    assert !@instance.valid?
  end

  test "uri is normalized" do
    @instance.uri = " test  test "
    assert_equal "test test", @instance.uri
  end

end
