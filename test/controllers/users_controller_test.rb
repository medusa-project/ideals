require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    get edit_user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "edit() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get edit_user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get edit_user_path(users(:admin))
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get users_path
    assert_redirected_to login_path
  end

  test "index() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get users_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get users_path
    assert_response :ok
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "show() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get user_path(users(:admin))
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    user = users(:admin)
    patch "/users/#{user.id}", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    user = users(:admin)
    patch "/users/#{user.id}", {}
    assert_redirected_to login_path
  end

  test "update() updates a user" do
    log_in_as(users(:admin))
    user = users(:norights)
    patch "/users/#{user.id}", {
        xhr: true,
        params: {
            user: {
                role_ids: [
                    roles(:sysadmin).id
                ]
            }
        }
    }
    user.reload
    assert user.sysadmin?
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch "/users/#{user.id}", {
        xhr: true,
        params: {
            user: {
                role_ids: [
                    roles(:sysadmin).id
                ]
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    user = users(:admin)
    patch "/users/#{user.id}", {
        xhr: true,
        params: {
            user: {
                role_ids: [
                    9999999
                ]
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent users" do
    log_in_as(users(:admin))
    patch "/users/99999999", {}
    assert_response :not_found
  end

end
