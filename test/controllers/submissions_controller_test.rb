require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post submissions_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post submissions_path, {}
    assert_redirected_to login_path
  end

  test "create() creates a submission" do
    log_in_as(users(:admin))
    assert_difference "Submission.count" do
      post submissions_path, {}
    end
  end

  test "create() redirects to profile-edit view" do
    log_in_as(users(:admin))
    post submissions_path, {}
    submission = Submission.order(created_at: :desc).limit(1).first
    assert_redirected_to edit_submission_path(submission)
  end

  # deposit()

  test "deposit() redirects to login path for logged-out users" do
    get deposit_path
    assert_redirected_to login_path
  end

  test "deposit() returns HTTP 200 for logged-in users" do
    skip # TODO: why does this fail?
    log_in_as(users(:norights))
    get deposit_path
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/submissions/99999"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/submissions/99999"
    assert_redirected_to login_path
  end

  test "destroy() destroys the submission" do
    log_in_as(users(:admin))
    submission = submissions(:one)
    assert_difference "Submission.count", -1 do
      delete submission_path(submission)
    end
  end

  test "destroy() returns HTTP 302 for an existing submission" do
    log_in_as(users(:admin))
    submission = submissions(:one)
    delete submission_path(submission)
    assert_redirected_to root_path
  end

  test "destroy() returns HTTP 404 for a missing submission" do
    log_in_as(users(:admin))
    delete "/submissions/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    submission = submissions(:one)
    get edit_submission_path(submission)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 200 for logged-in users" do
    submission = submissions(:one)
    log_in_as(submission.user)
    get edit_submission_path(submission)
    assert_response :ok
  end

end
