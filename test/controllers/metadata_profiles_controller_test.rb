require 'test_helper'

class MetadataProfilesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # clone()

  test "clone() redirects to login page for logged-out users" do
    profile = metadata_profiles(:uiuc_default)
    post metadata_profile_clone_path(profile)
    assert_redirected_to login_path
  end

  test "clone() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    profile = metadata_profiles(:uiuc_default)
    post metadata_profile_clone_path(profile)
    assert_response :forbidden
  end

  test "clone() redirects to the clone upon success" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_default)
    post metadata_profile_clone_path(profile)
    assert_redirected_to metadata_profile_path(MetadataProfile.order(created_at: :desc).first)
  end

  test "clone() clones a profile" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_default)
    assert_difference "MetadataProfile.count" do
      post metadata_profile_clone_path(profile)
    end
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post metadata_profiles_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post metadata_profiles_path,
         xhr: true,
         params: {
             metadata_profile: {
                 name: "cats"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post metadata_profiles_path,
         xhr: true,
         params: {
             metadata_profile: {
                 name:           "cats",
                 institution_id: user.institution.id
             }
         }
    assert_response :ok
  end

  test "create() creates a correct profile" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "MetadataProfile.count" do
      post metadata_profiles_path,
           xhr: true,
           params: {
               metadata_profile: {
                   institution_id: user.institution.id,
                   name:           "cats"
               }
           }
    end
    profile = MetadataProfile.order(created_at: :desc).limit(1).first
    assert profile.elements.count > 0
    assert_equal user.institution, profile.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post metadata_profiles_path,
         xhr: true,
         params: {
             metadata_profile: {
                 name: ""
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "destroy() destroys the profile" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_unused)
    assert_difference "MetadataProfile.count", -1 do
      delete metadata_profile_path(profile)
    end
  end

  test "destroy() returns HTTP 302 for an existing profile" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_unused)
    delete metadata_profile_path(profile)
    assert_redirected_to metadata_profiles_path
  end

  test "destroy() returns HTTP 404 for a missing profile" do
    log_in_as(users(:local_sysadmin))
    delete "/metadata-profiles/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    get edit_metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get edit_metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get edit_metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get edit_metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :ok

    get edit_metadata_profile_path(metadata_profiles(:uiuc_default),
                                   role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get metadata_profiles_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get metadata_profiles_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get metadata_profiles_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get metadata_profiles_path
    assert_response :ok

    get metadata_profiles_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get metadata_profile_path(metadata_profiles(:uiuc_default))
    assert_response :ok

    get metadata_profile_path(metadata_profiles(:uiuc_default),
                              role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/metadata-profiles/99999"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "update() updates a profile" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_default)
    patch metadata_profile_path(profile),
          xhr: true,
          params: {
              metadata_profile: {
                  name: "cats"
              }
          }
    profile.reload
    assert_equal "cats", profile.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_default)
    patch metadata_profile_path(profile),
          xhr: true,
          params: {
              metadata_profile: {
                  name: "cats"
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    profile = metadata_profiles(:uiuc_default)
    patch metadata_profile_path(profile),
          xhr: true,
          params: {
              metadata_profile: {
                  name: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent profiles" do
    log_in_as(users(:local_sysadmin))
    patch "/metadata-profiles/99999"
    assert_response :not_found
  end

end
