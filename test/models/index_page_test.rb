require "test_helper"

class IndexPageTest < ActiveSupport::TestCase

  setup do
    @instance = index_pages(:southwest_creators)
    assert @instance.valid?
  end

  # institution

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  # name

  test "name cannot be blank" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

end
