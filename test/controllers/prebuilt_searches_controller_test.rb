require 'test_helper'

class PrebuiltSearchesControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    @search = prebuilt_searches(:southwest_cats)
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post prebuilt_searches_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post prebuilt_searches_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post prebuilt_searches_path,
         xhr: true,
         params: {
           prebuilt_search: {
             name: "cats"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    post prebuilt_searches_path,
         xhr: true,
         params: {
           prebuilt_search: {
             name: "cats"
           }
         }
    assert_response :ok
  end

  test "create() creates a correct prebuilt search" do
    user = users(:southwest_admin)
    log_in_as(user)
    assert_difference "PrebuiltSearch.count" do
      post prebuilt_searches_path,
           xhr: true,
           params: {
             prebuilt_search: {
               name: "cats"
             }
           }
    end
    search = PrebuiltSearch.find_by_name("cats")
    assert_equal user.institution, search.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    post prebuilt_searches_path,
         xhr: true,
         params: {
           prebuilt_search: {
             name: ""
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete prebuilt_search_path(@search)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    delete prebuilt_search_path(@search)
    assert_redirected_to @search.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete prebuilt_search_path(@search)
    assert_response :forbidden
  end

  test "destroy() destroys the prebuilt search" do
    log_in_as(users(:southwest_admin))
    assert_difference "PrebuiltSearch.count", -1 do
      delete prebuilt_search_path(@search)
    end
  end

  test "destroy() returns HTTP 302 for an existing prebuilt search" do
    log_in_as(users(:southwest_admin))
    delete prebuilt_search_path(@search)
    assert_redirected_to prebuilt_searches_path
  end

  test "destroy() returns HTTP 404 for a missing prebuilt search" do
    log_in_as(users(:southwest_admin))
    delete "/prebuilt-searches/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_prebuilt_search_path(@search)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    get edit_prebuilt_search_path(@search)
    assert_redirected_to @search.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_prebuilt_search_path(@search)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get edit_prebuilt_search_path(@search)
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:southwest_admin))
    get edit_prebuilt_search_path(@search)
    assert_response :ok

    get edit_prebuilt_search_path(@search, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get prebuilt_searches_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get prebuilt_searches_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get prebuilt_searches_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get prebuilt_searches_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get prebuilt_searches_path
    assert_response :ok

    get prebuilt_searches_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_import_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_import_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_import_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get new_import_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get prebuilt_search_path(@search)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    get prebuilt_search_path(@search)
    assert_redirected_to @search.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get prebuilt_search_path(@search)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get prebuilt_search_path(@search)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_admin))
    get prebuilt_search_path(@search)
    assert_response :ok

    get prebuilt_search_path(@search, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch "/prebuilt-searches/99999"
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch "/prebuilt-searches/99999"
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch prebuilt_search_path(@search)
    assert_response :forbidden
  end

  test "update() updates a prebuilt search" do
    log_in_as(users(:southwest_admin))
    patch prebuilt_search_path(@search),
          xhr: true,
          params: {
            prebuilt_search: {
              name: "cats"
            }
          }
    @search.reload
    assert_equal "cats", @search.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    patch prebuilt_search_path(@search),
          xhr: true,
          params: {
            prebuilt_search: {
              name: "cats"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    patch prebuilt_search_path(@search),
          xhr: true,
          params: {
            prebuilt_search: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent prebuilt searches" do
    log_in_as(users(:southwest_admin))
    patch "/prebuilt-searches/99999"
    assert_response :not_found
  end

end
