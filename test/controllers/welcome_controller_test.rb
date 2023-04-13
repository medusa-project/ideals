require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # about()

  test "about() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get about_path
    assert_response :not_found
  end

  test "about() returns HTTP 200" do
    get about_path
    assert_response :ok
  end

  # contact()

  test "contact() returns HTTP 404 when the request is not via XHR" do
    post contact_path
    assert_response :not_found
  end

  test "contact() returns HTTP 400 for an incorrect CAPTCHA response for a
  logged-out user" do
    post contact_path, params: {
      answer:              "bogus",
      correct_answer_hash: "bogus"
    }, xhr: true
    assert_response :bad_request
  end

  test "contact() returns HTTP 400 when a comment is not supplied" do
    post contact_path, params: {
      answer:              "cats",
      correct_answer_hash: Digest::MD5.hexdigest("cats#{ApplicationHelper::CAPTCHA_SALT}"),
      page_url:            "http://example.org",
      name:                "My Name",
      email:               "me@example.org",
      comment:             ""
    }, xhr: true
    assert_response :bad_request
  end

  test "contact() sends an email when all arguments are valid" do
    post contact_path, params: {
      answer:              "cats",
      correct_answer_hash: Digest::MD5.hexdigest("cats#{ApplicationHelper::CAPTCHA_SALT}"),
      page_url:            "http://example.org",
      name:                "My Name",
      email:               "me@example.org",
      comment:             "Hello"
    }, xhr: true
    assert_response :ok
    assert !ActionMailer::Base.deliveries.empty?
  end

  # index()

  test "index() returns HTTP 200" do
    get root_path
    assert_response :ok
  end

end
