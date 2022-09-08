require 'test_helper'

class TasksControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get tasks_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get tasks_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get tasks_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get tasks_path
    assert_response :ok

    get tasks_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() redirects to login page for logged-out users" do
    get all_tasks_path
    assert_redirected_to login_path
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get all_tasks_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get all_tasks_path
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:norights))
    get task_path(tasks(:running)), xhr: true
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get task_path(tasks(:running)), xhr: true
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get task_path(tasks(:running)), xhr: true
    assert_response :ok

    get task_path(tasks(:running),
                  role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
