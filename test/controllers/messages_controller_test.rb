require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get messages_path
    assert_redirected_to Institution.default.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get messages_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get messages_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get messages_path
    assert_response :ok

    get messages_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to root page for logged-out users" do
    message = messages(:ingest_no_response)
    get message_path(message)
    assert_redirected_to Institution.default.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get message_path(messages(:ingest_no_response))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get message_path(messages(:ingest_no_response))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get message_path(messages(:ingest_no_response))
    assert_response :ok

    get messages_path(messages(:ingest_no_response),
                      role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
