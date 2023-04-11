require 'test_helper'

class RegisteredElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:uiuc).fqdn
    @element = registered_elements(:uiuc_dc_contributor)
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post registered_elements_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post registered_elements_path
    assert_redirected_to @element.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
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
    log_in_as(users(:uiuc_admin))
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

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete "/elements/bogus"
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    delete "/elements/bogus"
    assert_redirected_to @element.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    delete registered_element_path(registered_elements(:uiuc_unused))
    assert_response :forbidden
  end

  test "destroy() destroys the element" do
    log_in_as(users(:uiuc_admin))
    element = registered_elements(:uiuc_unused)
    assert_difference "RegisteredElement.count", -1 do
      delete registered_element_path(element)
    end
  end

  test "destroy() redirects to registered elements view for non-sysadmins" do
    log_in_as(users(:uiuc_admin))
    element = registered_elements(:uiuc_unused)
    delete registered_element_path(element)
    assert_redirected_to registered_elements_path
  end

  test "destroy() redirects to the element's institution for sysadmins" do
    log_in_as(users(:uiuc_sysadmin))
    element = registered_elements(:uiuc_unused)
    delete registered_element_path(element)
    assert_redirected_to institution_path(element.institution)
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:uiuc_admin))
    delete "/elements/bogus"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_registered_element_path(@element)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    get edit_registered_element_path(@element)
    assert_redirected_to @element.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get edit_registered_element_path(@element)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get edit_registered_element_path(@element)
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get registered_elements_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get registered_elements_path
    assert_redirected_to @element.institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get registered_elements_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get registered_elements_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get registered_elements_path
    assert_response :ok

    get registered_elements_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_registered_element_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_registered_element_path
    assert_redirected_to institutions(:uiuc).scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get new_registered_element_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_registered_element_path,
        params: {
          registered_element: {
            institution_id: institutions(:uiuc).id
          }
        }
    assert_response :ok
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    log_in_as(users(:uiuc))
    patch registered_element_path(@element)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch "/elements/bogus"
    assert_redirected_to @element.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    patch registered_element_path(@element)
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:uiuc_admin))
    patch registered_element_path(@element),
          xhr: true,
          params: {
              registered_element: {
                  name: "cats",
                  label: "Cats",
                  scope_note: "Mammals"
              }
          }
    @element.reload
    assert_equal "cats", @element.name
    assert_equal "Mammals", @element.scope_note
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    patch registered_element_path(@element),
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
    log_in_as(users(:uiuc_admin))
    patch registered_element_path(@element),
          xhr: true,
          params: {
              registered_element: {
                  name: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:uiuc_admin))
    patch "/elements/bogus"
    assert_response :not_found
  end

end
