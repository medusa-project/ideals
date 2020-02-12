require 'test_helper'

class MetadataProfileElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @profile = metadata_profiles(:empty)
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post metadata_profile_metadata_profile_elements_path(@profile), {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post metadata_profile_metadata_profile_elements_path(@profile), {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:admin))
    post metadata_profile_metadata_profile_elements_path(@profile), {
        xhr: true,
        params: {
            metadata_profile_element: {
                registered_element_id: registered_elements(:title).id,
                metadata_profile_id: @profile.id,
                label: "Title",
                index: 0
            }
        }
    }
    assert_response :ok
  end

  test "create() creates an element" do
    log_in_as(users(:admin))
    assert_difference "MetadataProfileElement.count" do
      post metadata_profile_metadata_profile_elements_path(@profile), {
          xhr: true,
          params: {
              metadata_profile_element: {
                  registered_element_id: registered_elements(:title).id,
                  metadata_profile_id: @profile.id,
                  label: "Title",
                  index: 0
              }
          }
      }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post metadata_profile_metadata_profile_elements_path(@profile), {
        xhr: true,
        params: {
            metadata_profile_element: {
                registered_element_id: registered_elements(:title).id,
                metadata_profile_id: @profile.id,
                index: -1 # invalid
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete metadata_profile_path(@profile) + "/elements/9999"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete metadata_profile_path(@profile) + "/elements/9999"
    assert_redirected_to login_path
  end

  test "destroy() destroys the element" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    assert_difference "MetadataProfileElement.count", -1 do
      delete metadata_profile_metadata_profile_element_path(element.metadata_profile, element)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    delete metadata_profile_metadata_profile_element_path(element.metadata_profile, element)
    assert_redirected_to element.metadata_profile
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:admin))
    delete metadata_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    element = metadata_profile_elements(:default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_redirected_to login_path
  end

  test "edit() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    element = metadata_profile_elements(:default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    patch metadata_profile_path(@profile) + "/elements/9999", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    patch metadata_profile_path(@profile) + "/elements/9999", {}
    assert_redirected_to login_path
  end

  test "update() updates an element" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element), {
        xhr: true,
        params: {
            metadata_profile_element: {
                registered_element_id: registered_elements(:title).id,
                metadata_profile_id: @profile.id,
                index: 2
            }
        }
    }
    element.reload
    assert_equal 2, element.index
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element), {
        xhr: true,
        params: {
            metadata_profile_element: {
                registered_element_id: registered_elements(:title).id,
                metadata_profile_id: @profile.id,
                label: "New Label",
                index: 0
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    element = metadata_profile_elements(:default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element), {
        xhr: true,
        params: {
            metadata_profile_element: {
                registered_element_id: registered_elements(:title).id,
                metadata_profile_id: @profile.id,
                index: -1 # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:admin))
    patch metadata_profile_path(@profile) + "/elements/9999", {}
    assert_response :not_found
  end

end
