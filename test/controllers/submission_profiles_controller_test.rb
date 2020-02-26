require 'test_helper'

class SubmissionProfilesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # clone()

  test "clone() redirects to login page for logged-out users" do
    profile = submission_profiles(:default)
    post submission_profile_clone_path(profile), {}
    assert_redirected_to login_path
  end

  test "clone() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    profile = submission_profiles(:default)
    post submission_profile_clone_path(profile), {}
    assert_redirected_to login_path
  end

  test "clone() redirects to the clone upon success" do
    log_in_as(users(:admin))
    profile = submission_profiles(:default)
    post submission_profile_clone_path(profile), {}
    assert_redirected_to submission_profile_path(SubmissionProfile.order(created_at: :desc).first)
  end

  test "clone() clones a profile" do
    log_in_as(users(:admin))
    profile = submission_profiles(:default)
    assert_difference "SubmissionProfile.count" do
      post submission_profile_clone_path(profile), {}
    end
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post submission_profiles_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post submission_profiles_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:admin))
    post submission_profiles_path, {
        xhr: true,
        params: {
            submission_profile: {
                name: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a profile" do
    log_in_as(users(:admin))
    assert_difference "SubmissionProfile.count" do
      post submission_profiles_path, {
          xhr: true,
          params: {
              submission_profile: {
                  name: "cats"
              }
          }
      }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post submission_profiles_path, {
        xhr: true,
        params: {
            submission_profile: {
                name: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/submission-profiles/99999"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/submission-profiles/99999"
    assert_redirected_to login_path
  end

  test "destroy() destroys the profile" do
    log_in_as(users(:admin))
    profile = submission_profiles(:unused)
    assert_difference "SubmissionProfile.count", -1 do
      delete "/submission-profiles/#{profile.id}"
    end
  end

  test "destroy() returns HTTP 302 for an existing profile" do
    log_in_as(users(:admin))
    profile = submission_profiles(:unused)
    delete "/submission-profiles/#{profile.id}"
    assert_redirected_to submission_profiles_path
  end

  test "destroy() returns HTTP 404 for a missing profile" do
    log_in_as(users(:admin))
    delete "/submission-profiles/99999"
    assert_response :not_found
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get submission_profiles_path
    assert_redirected_to login_path
  end

  test "index() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get submission_profiles_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get submission_profiles_path
    assert_response :ok
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get submission_profile_path(submission_profiles(:default))
    assert_redirected_to login_path
  end

  test "show() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get submission_profile_path(submission_profiles(:default))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get submission_profile_path(submission_profiles(:default))
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    patch "/submission-profiles/99999", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    patch "/submission-profiles/99999", {}
    assert_redirected_to login_path
  end

  test "update() updates a profile" do
    log_in_as(users(:admin))
    profile = submission_profiles(:default)
    patch "/submission-profiles/#{profile.id}", {
        xhr: true,
        params: {
            submission_profile: {
                name: "cats"
            }
        }
    }
    profile.reload
    assert_equal "cats", profile.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    profile = submission_profiles(:default)
    patch "/submission-profiles/#{profile.id}", {
        xhr: true,
        params: {
            submission_profile: {
                name: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    profile = submission_profiles(:default)
    patch "/submission-profiles/#{profile.id}", {
        xhr: true,
        params: {
            submission_profile: {
                name: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent profiles" do
    log_in_as(users(:admin))
    patch "/submission-profiles/99999", {}
    assert_response :not_found
  end

end
