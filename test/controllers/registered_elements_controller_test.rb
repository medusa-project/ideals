require 'test_helper'

class RegisteredElementsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post registered_elements_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post registered_elements_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:admin))
    post registered_elements_path, {
        xhr: true,
        params: {
            registered_element: {
                name: "cats",
                scope_note: "Mammals"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates an element" do
    log_in_as(users(:admin))
    post registered_elements_path, {
        xhr: true,
        params: {
            registered_element: {
                name: "cats",
                scope_note: "Mammals"
            }
        }
    }
    element =  RegisteredElement.find_by_name("cats")
    assert_equal "Mammals", element.scope_note
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post registered_elements_path, {
        xhr: true,
        params: {
            registered_element: {
                name: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/elements/bogus"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/elements/bogus"
    assert_redirected_to login_path
  end

  test "destroy() destroys the element" do
    log_in_as(users(:admin))
    element = registered_elements(:title)
    delete "/elements/#{element.name}"
    assert_raises ActiveRecord::RecordNotFound do
      RegisteredElement.find(element.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:admin))
    element = registered_elements(:title)
    delete "/elements/#{element.name}"
    assert_redirected_to registered_elements_path
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:admin))
    delete "/elements/bogus"
    assert_response :not_found
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get registered_elements_path
    assert_redirected_to login_path
  end

  test "index() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get registered_elements_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get registered_elements_path
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    patch "/elements/bogus", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    patch "/elements/bogus", {}
    assert_redirected_to login_path
  end

  test "update() updates an element" do
    log_in_as(users(:admin))
    element = registered_elements(:title)
    patch "/elements/#{element.name}", {
        xhr: true,
        params: {
            registered_element: {
                name: "cats",
                scope_note: "Mammals"
            }
        }
    }
    element.reload
    assert_equal "cats", element.name
    assert_equal "Mammals", element.scope_note
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    element = registered_elements(:title)
    patch "/elements/#{element.name}", {
        xhr: true,
        params: {
            registered_element: {
                name: "cats",
                scope_note: "Mammals"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    element = registered_elements(:title)
    patch "/elements/#{element.name}", {
        xhr: true,
        params: {
            registered_element: {
                name: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:admin))
    patch "/elements/bogus", {}
    assert_response :not_found
  end

end
