require 'test_helper'

class MetadataProfilesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post metadata_profiles_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post metadata_profiles_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:admin))
    post metadata_profiles_path, {
        xhr: true,
        params: {
            metadata_profile: {
                name: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a profile" do
    log_in_as(users(:admin))
    assert_difference "MetadataProfile.count" do
      post metadata_profiles_path, {
          xhr: true,
          params: {
              metadata_profile: {
                  name: "cats"
              }
          }
      }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post metadata_profiles_path, {
        xhr: true,
        params: {
            metadata_profile: {
                name: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/metadata-profiles/99999"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/metadata-profiles/99999"
    assert_redirected_to login_path
  end

  test "destroy() destroys the profile" do
    log_in_as(users(:admin))
    profile = metadata_profiles(:unused)
    assert_difference "MetadataProfile.count", -1 do
      delete "/metadata-profiles/#{profile.id}"
    end
  end

  test "destroy() returns HTTP 302 for an existing profile" do
    log_in_as(users(:admin))
    profile = metadata_profiles(:unused)
    delete "/metadata-profiles/#{profile.id}"
    assert_redirected_to metadata_profiles_path
  end

  test "destroy() returns HTTP 404 for a missing profile" do
    log_in_as(users(:admin))
    delete "/metadata-profiles/99999"
    assert_response :not_found
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get metadata_profiles_path
    assert_redirected_to login_path
  end

  test "index() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    get metadata_profiles_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    get metadata_profiles_path
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    patch "/metadata-profiles/99999", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    patch "/metadata-profiles/99999", {}
    assert_redirected_to login_path
  end

  test "update() updates a profile" do
    log_in_as(users(:admin))
    profile = metadata_profiles(:default)
    patch "/metadata-profiles/#{profile.id}", {
        xhr: true,
        params: {
            metadata_profile: {
                name: "cats"
            }
        }
    }
    profile.reload
    assert_equal "cats", profile.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    profile = metadata_profiles(:default)
    patch "/metadata-profiles/#{profile.id}", {
        xhr: true,
        params: {
            metadata_profile: {
                name: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    profile = metadata_profiles(:default)
    patch "/metadata-profiles/#{profile.id}", {
        xhr: true,
        params: {
            metadata_profile: {
                name: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent profiles" do
    log_in_as(users(:admin))
    patch "/metadata-profiles/99999", {}
    assert_response :not_found
  end

end
