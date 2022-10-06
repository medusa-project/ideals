require 'test_helper'

class ColorUtilsTest < ActiveSupport::TestCase

  # css_color?()

  test "css_color?() returns false for a blank argument" do
    assert !ColorUtils.css_color?(nil)
    assert !ColorUtils.css_color?("")
  end

  test "css_color?() works with color names" do
    assert ColorUtils.css_color?("blue")
  end

  test "css_color?() works with three-character hexadecimal colors" do
    assert ColorUtils.css_color?("#aa3")
    assert !ColorUtils.css_color?("ra3")
    assert !ColorUtils.css_color?("#ra3")
  end

  test "css_color?() works with six-character hexadecimal colors" do
    assert ColorUtils.css_color?("#aa3bc7")
    assert !ColorUtils.css_color?("aa3bc7")
    assert !ColorUtils.css_color?("#ra3bc7")
  end

  test "css_color?() works with rgb() syntax" do
    assert ColorUtils.css_color?("rgb(35,250,12)")
    assert ColorUtils.css_color?("rgb(35, 250, 12)")
    assert ColorUtils.css_color?("rgb(35,  250,  12)")
    assert !ColorUtils.css_color?("rgb(35, 250)")
    assert !ColorUtils.css_color?("rgb(35, 250, 12, 25)")
  end

  test "css_color?() works with rgba() syntax" do
    assert ColorUtils.css_color?("rgba(35,250,12,0.5)")
    assert ColorUtils.css_color?("rgba(35, 250, 12, 0.5)")
    assert ColorUtils.css_color?("rgba(35,  250,  12,  0.5)")
    assert !ColorUtils.css_color?("rgba(35, 250, 12)")
    assert !ColorUtils.css_color?("rgba(35, 250, 12, 5, 0.5)")
  end

  # maximize_text_contrast()

  test "maximize_text_contrast() returns the correct color" do
    assert_equal "#000000", ColorUtils.maximize_text_contrast("#a0c0d0")
    assert_equal "#ffffff", ColorUtils.maximize_text_contrast("#304050")
  end

  # to_rgb()

  test "to_rgb() works with three-character hexadecimal colors" do
    assert_equal ["a0".to_i(16), "70".to_i(16), "b0".to_i(16)],
                 ColorUtils.to_rgb("#a7b")
  end

  test "to_rgb() works with six-character hexadecimal colors" do
    assert_equal ["a7".to_i(16), "b4".to_i(16), "c8".to_i(16)],
                 ColorUtils.to_rgb("#a7b4c8")
  end

  test "to_rgb() works with rgb() syntax" do
    assert_equal [29, 180, 92], ColorUtils.to_rgb("rgb(29, 180, 92)")
  end

  test "to_rgb() works with rgba() syntax" do
    assert_equal [(29 * 0.5).round, (180 * 0.5).round, (92 * 0.5).round],
                 ColorUtils.to_rgb("rgba(29, 180, 92, 0.5)")
  end

  test "to_rgb() raises an error for an illegal argument" do
    assert_raises ArgumentError do
      ColorUtils.to_rgb("bogus")
    end
  end

end