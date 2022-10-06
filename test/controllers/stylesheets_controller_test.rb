require 'test_helper'

class StylesheetsControllerTest < ActionDispatch::IntegrationTest

  # show()

  test "show() returns HTTP 200" do
    get custom_styles_path
    assert_response :ok
  end

  test "show() returns a stylesheet" do
    get custom_styles_path
    assert response.body.include?("background-color")
  end

end
