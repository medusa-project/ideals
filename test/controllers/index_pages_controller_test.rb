require 'test_helper'

class IndexPagesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post index_pages_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post index_pages_path,
         xhr: true,
         params: {
           index_page: {
             name: "cats"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post index_pages_path,
         xhr: true,
         params: {
           index_page: {
             name: "cats"
           }
         }
    assert_response :ok
  end

  test "create() creates a correct index page" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "IndexPage.count" do
      post index_pages_path,
           xhr: true,
           params: {
             index_page: {
               name: "cats"
             }
           }
    end
    page = IndexPage.find_by_name("cats")
    assert_equal user.institution, page.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post index_pages_path,
         xhr: true,
         params: {
           index_page: {
             name: ""
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete index_page_path(index_pages(:southwest_creators))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "destroy() destroys the index page" do
    log_in_as(users(:local_sysadmin))
    page = index_pages(:southwest_creators)
    assert_difference "IndexPage.count", -1 do
      delete index_page_path(page)
    end
  end

  test "destroy() returns HTTP 302 for an existing index page" do
    log_in_as(users(:local_sysadmin))
    page = index_pages(:southwest_creators)
    delete index_page_path(page)
    assert_redirected_to index_pages_path
  end

  test "destroy() returns HTTP 404 for a missing index page" do
    log_in_as(users(:local_sysadmin))
    delete "/index-pages/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :ok

    get edit_index_page_path(index_pages(:southwest_creators),
                             role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get index_pages_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get index_pages_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get index_pages_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get index_pages_path
    assert_response :ok

    get index_pages_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() redirects to login page for logged-out users" do
    get new_import_path
    assert_redirected_to login_path
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get new_import_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_import_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200 for a page in a different institution" do
    log_in_as(users(:local_sysadmin))
    get index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for a page in the same institution" do
    page = index_pages(:southwest_creators)
    page.update!(institution: Institution.default)
    log_in_as(users(:local_sysadmin))
    get index_page_path(page)
    assert_response :ok
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/index-pages/99999"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "update() updates an index page" do
    log_in_as(users(:local_sysadmin))
    page = index_pages(:southwest_creators)
    patch index_page_path(page),
          xhr: true,
          params: {
            index_page: {
              name: "cats"
            }
          }
    page.reload
    assert_equal "cats", page.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    page = index_pages(:southwest_creators)
    patch index_page_path(page),
          xhr: true,
          params: {
            index_page: {
              name: "cats"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    page = index_pages(:southwest_creators)
    patch index_page_path(page),
          xhr: true,
          params: {
            index_page: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent index pages" do
    log_in_as(users(:local_sysadmin))
    patch "/index-pages/99999"
    assert_response :not_found
  end

end
