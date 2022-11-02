require 'test_helper'

class SubmissionProfilesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # clone()

  test "clone() redirects to login page for logged-out users" do
    profile = submission_profiles(:uiuc_default)
    post submission_profile_clone_path(profile)
    assert_redirected_to login_path
  end

  test "clone() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    profile = submission_profiles(:uiuc_default)
    post submission_profile_clone_path(profile)
    assert_response :forbidden
  end

  test "clone() redirects to the clone upon success" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    post submission_profile_clone_path(profile)
    assert_redirected_to submission_profile_path(SubmissionProfile.order(created_at: :desc).first)
  end

  test "clone() clones a profile" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    assert_difference "SubmissionProfile.count" do
      post submission_profile_clone_path(profile)
    end
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post submission_profiles_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post submission_profiles_path,
         xhr: true,
         params: {
             submission_profile: {
                 name: "cats"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post submission_profiles_path,
         xhr: true,
         params: {
             submission_profile: {
                 institution_id: user.institution.id,
                 name:           "cats"
             }
         }
    assert_response :ok
  end

  test "create() creates a profile and adds default elements to it" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "SubmissionProfile.count" do
      post submission_profiles_path,
           xhr: true,
           params: {
               submission_profile: {
                   institution_id: user.institution.id,
                   name:           "cats"
               }
           }
    end
    profile = SubmissionProfile.order(created_at: :desc).limit(1).first
    assert profile.elements.count > 0
    assert_equal user.institution, profile.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post submission_profiles_path,
         xhr: true,
         params: {
             submission_profile: {
                 name: ""
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete "/submission-profiles/99999"
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete submission_profile_path(submission_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "destroy() destroys the profile" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_unused)
    assert_difference "SubmissionProfile.count", -1 do
      delete submission_profile_path(profile)
    end
  end

  test "destroy() returns HTTP 302 for an existing profile" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_unused)
    delete submission_profile_path(profile)
    assert_redirected_to submission_profiles_path
  end

  test "destroy() returns HTTP 404 for a missing profile" do
    log_in_as(users(:local_sysadmin))
    delete "/submission-profiles/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    profile = submission_profiles(:uiuc_default)
    get edit_submission_profile_path(profile)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    profile = submission_profiles(:uiuc_default)
    get edit_submission_profile_path(profile)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    get edit_submission_profile_path(profile)
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get submission_profiles_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get submission_profiles_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get submission_profiles_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get submission_profiles_path
    assert_response :ok

    get submission_profiles_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get submission_profile_path(submission_profiles(:uiuc_default))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get submission_profile_path(submission_profiles(:uiuc_default))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get submission_profile_path(submission_profiles(:uiuc_default))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get submission_profile_path(submission_profiles(:uiuc_default))
    assert_response :ok

    get submission_profile_path(submission_profiles(:uiuc_default),
                                role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/submission-profiles/99999"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch submission_profile_path(submission_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "update() updates a profile" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    patch submission_profile_path(profile),
          xhr: true,
          params: {
              submission_profile: {
                  name: "cats"
              }
          }
    profile.reload
    assert_equal "cats", profile.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    patch submission_profile_path(profile),
          xhr: true,
          params: {
              submission_profile: {
                  name: "cats"
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    profile = submission_profiles(:uiuc_default)
    patch submission_profile_path(profile),
          xhr: true,
          params: {
              submission_profile: {
                  name: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent profiles" do
    log_in_as(users(:local_sysadmin))
    patch "/submission-profiles/99999"
    assert_response :not_found
  end

end
