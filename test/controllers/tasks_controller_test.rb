require 'test_helper'

class TasksControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get tasks_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get tasks_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get tasks_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get tasks_path
    assert_response :ok

    get tasks_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() redirects to root page for logged-out users" do
    get all_tasks_path
    assert_redirected_to @institution.scope_url
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest_admin))
    get all_tasks_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get all_tasks_path
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get all_tasks_path
    assert_response :ok

    get all_tasks_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 403 for logged-out users" do
    get task_path(tasks(:running)), xhr: true
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get task_path(tasks(:running)), xhr: true
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get task_path(tasks(:running)), xhr: true
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get task_path(tasks(:running)), xhr: true
    assert_response :ok

    get task_path(tasks(:running),
                  role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
