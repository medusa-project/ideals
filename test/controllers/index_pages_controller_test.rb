require 'test_helper'

class IndexPagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to root page for logged-out users" do
    post index_pages_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
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
    user = users(:southwest_admin)
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
    user = users(:southwest_admin)
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
    log_in_as(users(:southwest_admin))
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

  test "destroy() redirects to root page for logged-out users" do
    page = index_pages(:southwest_creators)
    delete index_page_path(page)
    assert_redirected_to page.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "destroy() destroys the index page" do
    log_in_as(users(:southwest_admin))
    page = index_pages(:southwest_creators)
    assert_difference "IndexPage.count", -1 do
      delete index_page_path(page)
    end
  end

  test "destroy() returns HTTP 302 for an existing index page" do
    log_in_as(users(:southwest_admin))
    page = index_pages(:southwest_creators)
    delete index_page_path(page)
    assert_redirected_to index_pages_path
  end

  test "destroy() returns HTTP 404 for a missing index page" do
    log_in_as(users(:southwest_admin))
    delete "/index-pages/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to root page for logged-out users" do
    page = index_pages(:southwest_creators)
    get edit_index_page_path(page)
    assert_redirected_to page.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:southwest_admin))
    get edit_index_page_path(index_pages(:southwest_creators))
    assert_response :ok

    get edit_index_page_path(index_pages(:southwest_creators),
                             role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get index_pages_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get index_pages_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get index_pages_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get index_pages_path
    assert_response :ok

    get index_pages_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

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

  test "show() returns HTTP 200 for a page in a different institution" do
    get index_page_path(index_pages(:northeast_creators))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for a page in the same institution" do
    get index_page_path(index_pages(:southwest_creators))
    assert_response :ok
  end

  # update()

  test "update() redirects to root page for logged-out users" do
    patch "/index-pages/99999"
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch index_page_path(index_pages(:southwest_creators))
    assert_response :forbidden
  end

  test "update() updates an index page" do
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
    patch "/index-pages/99999"
    assert_response :not_found
  end

end
