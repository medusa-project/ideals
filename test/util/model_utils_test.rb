require 'test_helper'

class ModelUtilsTest < ActiveSupport::TestCase

  # diff()

  test "diff() with only a before model" do
    model = {
      "key1" => "value",
      "key2" => "value"
    }
    result = ModelUtils.diff(model, nil)
    assert_equal 2, result.length
    assert_equal({
                   name: "key1",
                   before_value: "value",
                   op: :removed
                 }.sort, result[0].sort)
    assert_equal({
                   name: "key2",
                   before_value: "value",
                   op: :removed
                 }.sort, result[1].sort)
  end

  test "diff() with only an after model" do
    model = {
      "key1" => "value",
      "key2" => "value"
    }
    result = ModelUtils.diff(nil, model)
    assert_equal 2, result.length
    assert_equal({
                   name: "key1",
                   after_value: "value",
                   op: :added
                 }.sort, result[0].sort)
    assert_equal({
                   name: "key2",
                   after_value: "value",
                   op: :added
                 }.sort, result[1].sort)
  end

  test "diff() with both models" do
    model1 = {
      "key1" => "same value",
      "key2" => "value",
      "key3" => "value"
    }
    model2 = {
      "key1" => "same value",
      "key2" => "changed value",
      "key4" => "new property"
    }
    result = ModelUtils.diff(model1, model2)
    assert_equal 3, result.length
    assert_equal({
                    name: "key2",
                    before_value: "value",
                    after_value: "changed value",
                    op: :changed
                  }.sort, result[0].sort)
    assert_equal({
                   name: "key3",
                   before_value: "value",
                   op: :removed
                 }.sort, result[1].sort)
    assert_equal({
                   name: "key4",
                   after_value: "new property",
                   op: :added
                 }.sort, result[2].sort)
  end

  test "diff() treats missing and empty the same" do
    model1 = {}
    model2 = { "key1" => "" }
    result = ModelUtils.diff(model1, model2)
    assert_equal 0, result.length
  end

  test "diff() treats nil and empty the same" do
    model1 = { "key1" => nil }
    model2 = { "key1" => "" }
    result = ModelUtils.diff(model1, model2)
    assert_equal 0, result.length
  end

end
