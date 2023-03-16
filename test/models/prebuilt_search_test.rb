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
    @search = prebuilt_searches(:southwest_cats)
    assert @search.valid?
  end

  # institution

  test "institution is required" do
    @search.institution = nil
    assert !@search.valid?
  end

  # name

  test "name is required" do
    @search.name = nil
    assert !@search.valid?
  end

  # ordering_element

  test "ordering_element must be in the same institution" do
    @search.ordering_element = registered_elements(:northeast_dc_creator)
    assert !@search.valid?
  end

  # url_query()

  test "url_query() returns an empty string when the instance has no properties
  set" do
    assert_equal "", PrebuiltSearch.new.url_query
  end

  test "url_query() returns a correct query string" do
    parts = []
    @search.elements.sort_by(&:term).each do |element|
      parts << ["fq[]", "#{element.registered_element.indexed_keyword_field}:#{element.term}"]
    end
    parts << ["sort", @search.ordering_element.indexed_field]
    parts << ["direction", "asc"]
    assert_equal "?" + parts.map{ |p| p.map{ |a| StringUtils.url_encode(a) }.join("=") }.join("&"),
                 @search.url_query
  end

end
