require "test_helper"

class ElementNamespaceTest < ActiveSupport::TestCase

  setup do
    @namespace = element_namespaces(:southwest_dc)
    assert @namespace.valid?
  end

  # institution

  test "institution is required" do
    @namespace.institution = nil
    assert !@namespace.valid?
  end

  # prefix

  test "prefix is required" do
    @namespace.prefix = nil
    assert !@namespace.valid?
    @namespace.prefix = ""
    assert !@namespace.valid?
  end

  test "to_s() returns the prefix" do
    assert_equal @namespace.prefix, @namespace.to_s
  end

  # uri

  test "uri is required" do
    @namespace.uri = nil
    assert !@namespace.valid?
    @namespace.uri = ""
    assert !@namespace.valid?
  end

end
