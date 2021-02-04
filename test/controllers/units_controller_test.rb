require 'test_helper'

class UnitsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # chlldren()

  test "children() returns HTTP 404 for non-XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_children_path(units(:unit1))
    assert_response :not_found
  end

  test "children() returns HTTP 200 for XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_children_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  # collections()

  test "collections() returns HTTP 404 for non-XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_collections_path(units(:unit1))
    assert_response :not_found
  end

  test "collections() returns HTTP 200 for XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_collections_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post units_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post units_path,
         xhr: true,
         params: {
             unit: {
                 title: "New Unit"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:shibboleth_admin))
    post units_path,
         xhr: true,
         params: {
             unit: {
                 title: "New Unit"
             }
         }
    assert_response :ok
  end

  test "create() creates a unit" do
    log_in_as(users(:shibboleth_admin))
    assert_difference "Unit.count" do
      post units_path,
           xhr: true,
           params: {
               unit: {
                   title: "New Unit"
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post units_path,
         xhr: true,
         params: {
             unit: {
                 title: ""
             }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    unit = units(:unit1)
    delete unit_path(unit)
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    delete unit_path(unit)
    assert_response :forbidden
  end

  test "destroy() destroys the unit" do
    log_in_as(users(:admin))
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:empty)
    delete unit_path(unit)
    assert_raises ActiveRecord::RecordNotFound do
      Unit.find(unit.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing unit" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    delete unit_path(unit)
    assert_redirected_to units_path
  end

  test "destroy() returns HTTP 404 for a missing unit" do
    log_in_as(users(:admin))
    delete "/units/bogus"
    assert_response :not_found
  end

  # edit_access()

  test "edit_access() redirects to login page for logged-out users" do
    unit = units(:unit1)
    get unit_edit_access_path(unit), xhr: true
    assert_redirected_to login_path
  end

  test "edit_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    get unit_edit_access_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_access_path(unit)
    assert_response :not_found
  end

  test "edit_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_access_path(unit), xhr: true
    assert_response :ok
  end

  # edit_membership()

  test "edit_membership() redirects to login page for logged-out users" do
    unit = units(:unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_redirected_to login_path
  end

  test "edit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_membership_path(unit)
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() redirects to login page for logged-out users" do
    unit = units(:unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_properties_path(unit)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 200 for HTML" do
    get units_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for JSON" do
    get units_path(format: :json)
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200 for HTML" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_path(units(:unit1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_path(units(:unit1), format: :json)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:admin))
    get unit_path(units(:unit1))
    assert_select("#access-tab")

    get unit_path(units(:unit1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    unit = units(:unit1)
    patch unit_path(unit)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    patch unit_path(unit)
    assert_response :forbidden
  end

  test "update() returns HTTP 403 when updating the unit parent_id to a unit of
  which the current user is not an effective administrator" do
    log_in_as(users(:unit1_admin))
    unit = units(:unit1)
    unit.update!(primary_administrator: nil) # child units cannot have a primary admin
    patch unit_path(unit),
          xhr: true,
          params: {
            unit: {
              parent_id: units(:unit2).id
            }
          }
    assert_response :forbidden
  end

  test "update() updates a unit" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch unit_path(unit),
          xhr: true,
          params: {
              unit: {
                  title: "cats"
              }
          }
    unit.reload
    assert_equal "cats", unit.title
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch unit_path(unit),
          xhr: true,
          params: {
              unit: {
                  title: "cats"
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch unit_path(unit),
          xhr: true,
          params: {
              unit: {
                  title: "" # invalid
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent units" do
    log_in_as(users(:admin))
    patch "/units/bogus"
    assert_response :not_found
  end

end
