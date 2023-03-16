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
    @search = prebuilt_searches(:southwest_creators)
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

  test "url_query() returns a correct query string" do
    assert_equal sprintf("?sort=%s&direction=asc",
                         @search.ordering_element.indexed_field),
                 @search.url_query
  end

end
