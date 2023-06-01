require 'test_helper'

class SubmissionProfileElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:uiuc).fqdn
    @profile = submission_profiles(:uiuc_empty)
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post submission_profile_submission_profile_elements_path(@profile)
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post submission_profile_submission_profile_elements_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:uiuc_dc_title).id,
                 submission_profile_id: @profile.id,
                 position: 0
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:uiuc_dc_title).id,
                 submission_profile_id: @profile.id,
                 position: 0
             }
         }
    assert_response :ok
  end

  test "create() creates an element" do
    log_in_as(users(:uiuc_admin))
    assert_difference "SubmissionProfileElement.count" do
      post submission_profile_submission_profile_elements_path(@profile),
           xhr: true,
           params: {
               submission_profile_element: {
                   registered_element_id: registered_elements(:uiuc_dc_title).id,
                   submission_profile_id: @profile.id,
                   position: 0
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:uiuc_dc_title).id,
                 submission_profile_id: @profile.id,
                 position: -1 # invalid
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    delete submission_profile_path(@profile) + "/elements/9999"
    assert_redirected_to @profile.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    delete submission_profile_submission_profile_element_path(@profile,
                                                              submission_profile_elements(:uiuc_default_subject))
    assert_response :forbidden
  end

  test "destroy() destroys the element" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    assert_difference "SubmissionProfileElement.count", -1 do
      delete submission_profile_submission_profile_element_path(element.submission_profile,
                                                                element)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    delete submission_profile_submission_profile_element_path(element.submission_profile,
                                                              element)
    assert_redirected_to element.submission_profile
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:uiuc_admin))
    delete submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    element = submission_profile_elements(:uiuc_default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    element = submission_profile_elements(:uiuc_default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_redirected_to @profile.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    element = submission_profile_elements(:uiuc_default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_response :ok
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_submission_profile_submission_profile_element_path(@profile)
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_submission_profile_submission_profile_element_path(@profile)
    assert_redirected_to @profile.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    get new_submission_profile_submission_profile_element_path(@profile)
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_submission_profile_submission_profile_element_path(@profile)
    assert_response :ok
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch submission_profile_path(@profile) + "/elements/9999"
    assert_redirected_to @profile.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    element = submission_profile_elements(:uiuc_default_title)
    patch submission_profile_submission_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:uiuc_dc_title).id,
                  submission_profile_id: @profile.id,
                  position: 2
              }
          }
    element.reload
    assert_equal 2, element.position
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:uiuc_dc_title).id,
                  submission_profile_id: @profile.id,
                  position: 0
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
    element = submission_profile_elements(:uiuc_default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:uiuc_dc_title).id,
                  submission_profile_id: @profile.id,
                  position: -1 # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:uiuc_admin))
    patch submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

end
