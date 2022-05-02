require 'test_helper'

class SubmissionProfileElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @profile = submission_profiles(:empty)
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post submission_profile_submission_profile_elements_path(@profile)
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:dc_title).id,
                 submission_profile_id: @profile.id,
                 position: 0
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:dc_title).id,
                 submission_profile_id: @profile.id,
                 position: 0
             }
         }
    assert_response :ok
  end

  test "create() creates an element" do
    log_in_as(users(:local_sysadmin))
    assert_difference "SubmissionProfileElement.count" do
      post submission_profile_submission_profile_elements_path(@profile),
           xhr: true,
           params: {
               submission_profile_element: {
                   registered_element_id: registered_elements(:dc_title).id,
                   submission_profile_id: @profile.id,
                   position: 0
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post submission_profile_submission_profile_elements_path(@profile),
         xhr: true,
         params: {
             submission_profile_element: {
                 registered_element_id: registered_elements(:dc_title).id,
                 submission_profile_id: @profile.id,
                 position: -1 # invalid
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete submission_profile_path(@profile) + "/elements/9999"
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete submission_profile_submission_profile_element_path(@profile,
                                                              submission_profile_elements(:default_subject))
    assert_response :forbidden
  end

  test "destroy() destroys the element" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    assert_difference "SubmissionProfileElement.count", -1 do
      delete submission_profile_submission_profile_element_path(element.submission_profile,
                                                                element)
    end
  end

  test "destroy() returns HTTP 302 for an existing element" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    delete submission_profile_submission_profile_element_path(element.submission_profile,
                                                              element)
    assert_redirected_to element.submission_profile
  end

  test "destroy() returns HTTP 404 for a missing element" do
    log_in_as(users(:local_sysadmin))
    delete submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    element = submission_profile_elements(:default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    element = submission_profile_elements(:default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    get edit_submission_profile_submission_profile_element_path(@profile, element)
    assert_response :ok
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch submission_profile_path(@profile) + "/elements/9999"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    element = submission_profile_elements(:default_title)
    patch submission_profile_submission_profile_element_path(@profile, element)
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:dc_title).id,
                  submission_profile_id: @profile.id,
                  position: 2
              }
          }
    element.reload
    assert_equal 2, element.position
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:dc_title).id,
                  submission_profile_id: @profile.id,
                  position: 0
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    element = submission_profile_elements(:default_title)
    patch submission_profile_submission_profile_element_path(@profile, element),
          xhr: true,
          params: {
              submission_profile_element: {
                  registered_element_id: registered_elements(:dc_title).id,
                  submission_profile_id: @profile.id,
                  position: -1 # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:local_sysadmin))
    patch submission_profile_path(@profile) + "/elements/9999"
    assert_response :not_found
  end

end
