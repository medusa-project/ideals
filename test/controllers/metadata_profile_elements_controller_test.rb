require 'test_helper'

class MetadataProfileElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southeast).fqdn
    @profile = metadata_profiles(:southeast_empty)
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post metadata_profile_metadata_profile_elements_path(@profile)
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post metadata_profile_metadata_profile_elements_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post metadata_profile_metadata_profile_elements_path(@profile),
         xhr: true,
         params: {
             metadata_profile_element: {
                 registered_element_id: registered_elements(:southeast_dc_title).id,
                 metadata_profile_id:   @profile.id,
                 label:                 "Title",
                 position:              0
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:southeast_admin))
    post metadata_profile_metadata_profile_elements_path(@profile),
         xhr: true,
         params: {
             metadata_profile_element: {
                 registered_element_id: registered_elements(:southeast_dc_title).id,
                 metadata_profile_id:   @profile.id,
                 label:                 "Title",
                 position:              0
             }
         }
    assert_response :ok
  end

  test "create() creates an element" do
    log_in_as(users(:southeast_admin))
    assert_difference "MetadataProfileElement.count" do
      post metadata_profile_metadata_profile_elements_path(@profile),
           xhr: true,
           params: {
               metadata_profile_element: {
                   registered_element_id: registered_elements(:southeast_dc_title).id,
                   metadata_profile_id:   @profile.id,
                   label:                 "Title",
                   position:              0
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southeast_admin))
    post metadata_profile_metadata_profile_elements_path(@profile),
         xhr: true,
         params: {
             metadata_profile_element: {
                 registered_element_id: registered_elements(:southeast_dc_title).id,
                 metadata_profile_id:   @profile.id,
                 position:              -1 # invalid
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    element = metadata_profile_elements(:southeast_default_description)
    delete metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    element = metadata_profile_elements(:southeast_default_description)
    delete metadata_profile_metadata_profile_element_path(@profile, element)
    assert_redirected_to @profile.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    element = metadata_profile_elements(:southeast_default_description)
    delete metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "destroy() destroys the element" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    assert_difference "MetadataProfileElement.count", -1 do
      delete metadata_profile_metadata_profile_element_path(element.metadata_profile,
                                                            element)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    delete metadata_profile_metadata_profile_element_path(element.metadata_profile,
                                                          element)
    assert_redirected_to element.metadata_profile
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:southeast_admin))
    delete metadata_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    element = metadata_profile_elements(:southeast_default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    element = metadata_profile_elements(:southeast_default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_redirected_to @profile.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    element = metadata_profile_elements(:southeast_default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    get edit_metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :ok
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_metadata_profile_metadata_profile_element_path(@profile)
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_metadata_profile_metadata_profile_element_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    get new_metadata_profile_metadata_profile_element_path(@profile)
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southeast_admin))
    get new_metadata_profile_metadata_profile_element_path(@profile)
    assert_response :ok
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element)
    assert_redirected_to @profile.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element),
          xhr: true,
          params: {
              metadata_profile_element: {
                  registered_element_id: registered_elements(:southeast_dc_title).id,
                  metadata_profile_id:   @profile.id,
                  position:              2
              }
          }
    element.reload
    assert_equal 2, element.position
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element),
          xhr: true,
          params: {
              metadata_profile_element: {
                  registered_element_id: registered_elements(:southeast_dc_title).id,
                  metadata_profile_id:   @profile.id,
                  label:                 "New Label",
                  position:              0
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southeast_admin))
    element = metadata_profile_elements(:southeast_default_title)
    patch metadata_profile_metadata_profile_element_path(@profile, element),
          xhr: true,
          params: {
              metadata_profile_element: {
                  registered_element_id: registered_elements(:southeast_dc_title).id,
                  metadata_profile_id:   @profile.id,
                  position:              -1 # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:southeast_admin))
    patch metadata_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

end
