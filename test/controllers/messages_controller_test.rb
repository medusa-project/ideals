require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get messages_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get messages_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get messages_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get messages_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get messages_path
    assert_response :ok

    get messages_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # resend()

  test "resend() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    message = messages(:ingest_no_response)
    post message_resend_path(message)
    assert_response :not_found
  end

  test "resend() redirects to root page for logged-out users" do
    message = messages(:ingest_no_response)
    post message_resend_path(message)
    assert_redirected_to @institution.scope_url
  end

  test "resend() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post message_resend_path(messages(:ingest_no_response))
    assert_response :forbidden
  end

  test "resend() redirects back for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    post message_resend_path(messages(:ingest_no_response))
    assert_redirected_to messages_path
  end

  test "resend() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    post message_resend_path(messages(:ingest_no_response))
    assert_response :found

    get messages_path(messages(:ingest_no_response),
                      role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    message = messages(:ingest_no_response)
    get message_path(message)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    message = messages(:ingest_no_response)
    get message_path(message)
    assert_redirected_to @institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get message_path(messages(:ingest_no_response))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get message_path(messages(:ingest_no_response))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get message_path(messages(:ingest_no_response))
    assert_response :ok

    get messages_path(messages(:ingest_no_response),
                      role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
