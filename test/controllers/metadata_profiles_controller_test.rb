require 'test_helper'

class MetadataProfilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:uiuc).fqdn
    @profile = metadata_profiles(:uiuc_default)
  end

  teardown do
    log_out
  end

  # clone()

  test "clone() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post metadata_profile_clone_path(@profile)
    assert_response :not_found
  end

  test "clone() redirects to root page for logged-out users" do
    post metadata_profile_clone_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "clone() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    post metadata_profile_clone_path(@profile)
    assert_response :forbidden
  end

  test "clone() redirects to the clone upon success" do
    log_in_as(users(:uiuc_admin))
    post metadata_profile_clone_path(@profile)
    assert_redirected_to metadata_profile_path(MetadataProfile.order(created_at: :desc).first)
  end

  test "clone() clones a profile" do
    log_in_as(users(:uiuc_admin))
    assert_difference "MetadataProfile.count" do
      post metadata_profile_clone_path(@profile)
    end
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post metadata_profiles_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post metadata_profiles_path
    assert_redirected_to @profile.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
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
             },
             elements: [
               institutions(:uiuc).registered_elements.find_by_name("dc:title").id
             ]
           }
    end
    profile = MetadataProfile.order(created_at: :desc).limit(1).first
    assert_equal 1, profile.elements.count
    assert_equal user.institution, profile.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
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

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @profile = metadata_profiles(:uiuc_unused)
    delete metadata_profile_path(@profile)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    @profile = metadata_profiles(:uiuc_unused)
    delete metadata_profile_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    delete metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "destroy() destroys the profile" do
    log_in_as(users(:uiuc_admin))
    profile = metadata_profiles(:uiuc_unused)
    assert_difference "MetadataProfile.count", -1 do
      delete metadata_profile_path(profile)
    end
  end

  test "destroy() redirects to metadata profiles view for non-sysadmins" do
    log_in_as(users(:uiuc_admin))
    profile = metadata_profiles(:uiuc_unused)
    delete metadata_profile_path(profile)
    assert_redirected_to metadata_profiles_path
  end

  test "destroy() redirects to the profile's institution for sysadmins" do
    log_in_as(users(:uiuc_sysadmin))
    profile = metadata_profiles(:uiuc_unused)
    delete metadata_profile_path(profile)
    assert_redirected_to institution_path(profile.institution)
  end

  test "destroy() returns HTTP 404 for a missing profile" do
    log_in_as(users(:uiuc_admin))
    delete "/metadata-profiles/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_metadata_profile_path(@profile)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    get edit_metadata_profile_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get edit_metadata_profile_path(@profile)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get edit_metadata_profile_path(@profile)
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get edit_metadata_profile_path(@profile)
    assert_response :ok

    get edit_metadata_profile_path(@profile, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_metadata_profile_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_metadata_profile_path
    assert_redirected_to @profile.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get new_metadata_profile_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_metadata_profile_path,
        params: {
          metadata_profile: {
            institution_id: institutions(:uiuc).id
          }
        }
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get metadata_profile_path(@profile)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    get metadata_profile_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get metadata_profile_path(@profile)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get metadata_profile_path(@profile)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get metadata_profile_path(@profile)
    assert_response :ok

    get metadata_profile_path(@profile, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    log_in_as(users(:uiuc))
    patch metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch "/metadata-profiles/99999"
    assert_redirected_to @profile.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    patch metadata_profile_path(metadata_profiles(:uiuc_unused))
    assert_response :forbidden
  end

  test "update() updates a profile" do
    log_in_as(users(:uiuc_admin))
    patch metadata_profile_path(@profile),
          xhr: true,
          params: {
            metadata_profile: {
              institution_id: institutions(:uiuc).id,
              name: "cats"
            }
          }
    @profile.reload
    assert_equal "cats", @profile.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    patch metadata_profile_path(@profile),
          xhr: true,
          params: {
            metadata_profile: {
              institution_id: institutions(:uiuc).id,
              name:           "cats"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
    patch metadata_profile_path(@profile),
          xhr: true,
          params: {
            metadata_profile: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent profiles" do
    log_in_as(users(:uiuc_admin))
    patch "/metadata-profiles/99999"
    assert_response :not_found
  end

end
