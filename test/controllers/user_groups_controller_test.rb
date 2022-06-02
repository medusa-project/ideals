require 'test_helper'

class UserGroupsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post user_groups_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post user_groups_path,
         xhr: true,
         params: {
             user_group: {
                 key:  "cats",
                 name: "cats"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    post user_groups_path,
         xhr: true,
         params: {
             user_group: {
                 key:  "cats",
                 name: "cats"
             }
         }
    assert_response :ok
  end

  test "create() creates a user group" do
    log_in_as(users(:local_sysadmin))
    assert_difference "UserGroup.count" do
      post user_groups_path,
           xhr: true,
           params: {
               user_group: {
                   key:  "cats",
                   name: "cats"
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post user_groups_path,
         xhr: true,
         params: {
             user_group: {
                 key:  "cats",
                 name: ""
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete "/user-groups/99999"
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete user_group_path(user_groups(:unused))
    assert_response :forbidden
  end

  test "destroy() destroys the group" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:unused)
    assert_difference "UserGroup.count", -1 do
      delete user_group_path(group)
    end
  end

  test "destroy() returns HTTP 302 for an existing group" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:unused)
    delete user_group_path(group)
    assert_redirected_to user_groups_path
  end

  test "destroy() returns HTTP 404 for a missing group" do
    log_in_as(users(:local_sysadmin))
    delete "/user-groups/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get edit_user_group_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get edit_user_group_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get edit_user_group_path(group), xhr: true
    assert_response :ok
  end

  # edit_ad_groups()

  test "edit_ad_groups() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_ad_groups_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_ad_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_ad_groups_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_ad_groups() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_ad_groups_path(group)
    assert_response :not_found
  end

  test "edit_ad_groups() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_ad_groups_path(group), xhr: true
    assert_response :ok
  end

  # edit_affiliations()

  test "edit_affiliations() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_affiliations_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_affiliations() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_affiliations_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_affiliations() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_affiliations_path(group)
    assert_response :not_found
  end

  test "edit_affiliations() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_affiliations_path(group), xhr: true
    assert_response :ok
  end

  # edit_departments()

  test "edit_departments() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_departments_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_departments() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_departments_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_departments() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_departments_path(group)
    assert_response :not_found
  end

  test "edit_departments() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_departments_path(group), xhr: true
    assert_response :ok
  end

  # edit_email_patterns()

  test "edit_email_patterns() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_email_patterns_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_email_patterns() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_email_patterns_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_email_patterns() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_email_patterns_path(group)
    assert_response :not_found
  end

  test "edit_email_patterns() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_email_patterns_path(group), xhr: true
    assert_response :ok
  end

  # edit_hosts()

  test "edit_hosts() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_hosts_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_hosts() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_hosts_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_hosts() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_hosts_path(group)
    assert_response :not_found
  end

  test "edit_hosts() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_hosts_path(group), xhr: true
    assert_response :ok
  end

  # edit_local_users()

  test "edit_local_users() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_local_users_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_local_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_local_users_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_local_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_local_users_path(group)
    assert_response :not_found
  end

  test "edit_local_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_local_users_path(group), xhr: true
    assert_response :ok
  end

  # edit_netid_users()

  test "edit_netid_users() returns HTTP 403 for logged-out users" do
    group = user_groups(:temp)
    get user_group_edit_netid_users_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_netid_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    group = user_groups(:temp)
    get user_group_edit_netid_users_path(group), xhr: true
    assert_response :forbidden
  end

  test "edit_netid_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_netid_users_path(group)
    assert_response :not_found
  end

  test "edit_netid_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:temp)
    get user_group_edit_netid_users_path(group), xhr: true
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get user_groups_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_groups_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_groups_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_groups_path
    assert_response :ok

    get user_groups_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get user_group_path(user_groups(:sysadmin))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get user_group_path(user_groups(:sysadmin))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get user_group_path(user_groups(:sysadmin))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get user_group_path(user_groups(:sysadmin))
    assert_response :ok

    get user_group_path(user_groups(:sysadmin), role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/user-groups/99999"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch user_group_path(user_groups(:unused))
    assert_response :forbidden
  end

  test "update() updates a user group" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:sysadmin)
    patch user_group_path(group),
          xhr: true,
          params: {
              user_group: {
                  key:  "cats",
                  name: "cats"
              }
          }
    group.reload
    assert_equal "cats", group.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:sysadmin)
    patch user_group_path(group),
          xhr: true,
          params: {
              user_group: {
                  key:  "cats",
                  name: "cats"
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    group = user_groups(:sysadmin)
    patch user_group_path(group),
          xhr: true,
          params: {
              user_group: {
                  key:  "cats",
                  name: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent user groups" do
    log_in_as(users(:local_sysadmin))
    patch "/user-groups/99999"
    assert_response :not_found
  end

end
