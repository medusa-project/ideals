require "test_helper"

class PrebuiltSearchTest < ActiveSupport::TestCase

  class OrderingDirectionTest < ActiveSupport::TestCase

    test "all() returns all ordering directions" do
      assert_equal [0, 1], PrebuiltSearch::OrderingDirection::all.sort
    end

    test "label() raises an error for an invalid type" do
      assert_raises ArgumentError do
        PrebuiltSearch::OrderingDirection.label(840)
      end
    end

    test "label() returns a correct label" do
      assert_equal "Ascending",
                   PrebuiltSearch::OrderingDirection.label(PrebuiltSearch::OrderingDirection::ASCENDING)
    end
  end

  setup do
    @instance = prebuilt_searches(:southwest_cats)
    assert @instance.valid?
  end

  # institution

  test "institution is required" do
    @instance.institution = nil
    assert !@instance.valid?
  end

  # name

  test "name is required" do
    @instance.name = nil
    assert !@instance.valid?
  end

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

  # ordering_element

  test "ordering_element must be in the same institution" do
    @instance.ordering_element = registered_elements(:northeast_dc_creator)
    assert !@instance.valid?
  end

  # url_query()

  test "url_query() returns a correct query string" do
    parts = []
    parts << ["prebuilt_search_id", @instance.id]
    @instance.elements.sort_by(&:term).each do |element|
      parts << ["elements[#{element.registered_element.name}]", element.term]
    end
    parts << ["sort", @instance.ordering_element.indexed_sort_field]
    parts << ["direction", "asc"]
    assert_equal "?" + parts.map{ |p| p.map{ |a| StringUtils.url_encode(a) }.join("=") }.join("&"),
                 @instance.url_query
  end

end
