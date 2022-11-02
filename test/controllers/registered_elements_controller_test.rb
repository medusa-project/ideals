require 'test_helper'

class RegisteredElementsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post registered_elements_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post registered_elements_path,
         xhr: true,
         params: {
             registered_element: {
                 name: "cats",
                 label: "Cats",
                 scope_note: "Mammals"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post registered_elements_path,
         xhr: true,
         params: {
             registered_element: {
                 institution_id: user.institution.id,
                 name:           "cats",
                 label:          "Cats",
                 scope_note:     "Mammals"
             }
         }
    assert_response :ok
  end

  test "create() creates a correct element" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "RegisteredElement.count" do
      post registered_elements_path,
           xhr: true,
           params: {
               registered_element: {
                   institution_id: user.institution.id,
                   name: "cats",
                   label: "Cats",
                   scope_note: "Mammals"
               }
           }
    end
    element = RegisteredElement.order(created_at: :desc).limit(1).first
    assert_equal user.institution, element.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post registered_elements_path,
         xhr: true,
         params: {
             registered_element: {
                 name: ""
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete "/elements/bogus"
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete registered_element_path(registered_elements(:uiuc_unused))
    assert_response :forbidden
  end

  test "destroy() destroys the element" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_unused)
    assert_difference "RegisteredElement.count", -1 do
      delete registered_element_path(element)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_dc_title)
    delete registered_element_path(element)
    assert_redirected_to registered_elements_path
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:local_sysadmin))
    delete "/elements/bogus"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    element = registered_elements(:uiuc_dc_title)
    get edit_registered_element_path(element)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    element = registered_elements(:uiuc_dc_title)
    get edit_registered_element_path(element)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_dc_title)
    get edit_registered_element_path(element)
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get registered_elements_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get registered_elements_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get registered_elements_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get registered_elements_path
    assert_response :ok

    get registered_elements_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/elements/bogus"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch registered_element_path(registered_elements(:uiuc_dc_description))
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_dc_contributor)
    patch "/elements/#{element.name}",
          xhr: true,
          params: {
              registered_element: {
                  name: "cats",
                  label: "Cats",
                  scope_note: "Mammals"
              }
          }
    element.reload
    assert_equal "cats", element.name
    assert_equal "Mammals", element.scope_note
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_dc_contributor)
    patch registered_element_path(element),
          xhr: true,
          params: {
              registered_element: {
                  name: "cats",
                  scope_note: "Mammals"
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    element = registered_elements(:uiuc_dc_title)
    patch registered_element_path(element),
          xhr: true,
          params: {
              registered_element: {
                  name: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:local_sysadmin))
    patch "/elements/bogus"
    assert_response :not_found
  end

end
