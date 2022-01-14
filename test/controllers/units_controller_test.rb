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

  test "children() returns HTTP 410 for a buried unit" do
    get unit_children_path(units(:buried)), xhr: true
    assert_response :gone
  end

  test "children() returns HTTP 200 for XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_children_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  # collections_tree_fragment()

  test "collections_tree_fragment() returns HTTP 404 for non-XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_collections_tree_fragment_path(units(:unit1))
    assert_response :not_found
  end

  test "collections_tree_fragment() returns HTTP 410 for a buried unit" do
    get unit_collections_tree_fragment_path(units(:buried)), xhr: true
    assert_response :gone
  end

  test "collections_tree_fragment() returns HTTP 200 for XHR requests" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_collections_tree_fragment_path(units(:unit1)), xhr: true
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
    user = users(:uiuc_admin)
    log_in_as(user)
    post units_path,
         xhr: true,
         params: {
             unit: {
                 institution_id: user.institution.id,
                 title:          "New Unit"
             }
         }
    assert_response :ok
  end

  test "create() creates a unit" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "Unit.count" do
      post units_path,
           xhr: true,
           params: {
               unit: {
                   institution_id: user.institution.id,
                   title:          "New Unit"
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
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

  test "destroy() returns HTTP 410 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    delete unit_path(unit)
    assert_response :gone
  end

  test "destroy() buries the unit" do
    log_in_as(users(:local_sysadmin))
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:empty)
    delete unit_path(unit)
    unit.reload
    assert unit.buried
  end

  test "destroy() redirects to the unit when the delete fails" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    delete unit_path(unit)
    assert_redirected_to unit_path(unit)
  end

  test "destroy() redirects to the parent unit, if available, if the delete
  succeeds" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1_unit1)
    delete unit_path(unit)
    assert_redirected_to unit_path(unit.parent)
  end

  test "destroy() redirects to the units path if there is no parent unit and
  the delete succeeds" do
    log_in_as(users(:local_sysadmin))
    unit = units(:empty)
    delete unit_path(unit)
    assert_redirected_to units_path
  end

  test "destroy() returns HTTP 404 for a missing unit" do
    log_in_as(users(:local_sysadmin))
    delete "/units/bogus"
    assert_response :not_found
  end

  # edit_administrators()

  test "edit_administrators() redirects to login page for logged-out users" do
    unit = units(:unit1)
    get unit_edit_administrators_path(unit), xhr: true
    assert_redirected_to login_path
  end

  test "edit_administrators() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    get unit_edit_administrators_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_administrators() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_edit_administrators_path(unit)
    assert_response :not_found
  end

  test "edit_administrators() returns HTTP 410 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    get unit_edit_administrators_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_administrators() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_edit_administrators_path(unit), xhr: true
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
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_edit_membership_path(unit)
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 404 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_edit_properties_path(unit)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 404 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
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

  # item_download_counts()

  test "item_download_counts() returns HTTP 200 for HTML" do
    get unit_item_download_counts_path(units(:unit1))
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 200 for CSV" do
    get unit_item_download_counts_path(units(:unit1), format: :csv)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 410 for a buried unit" do
    get unit_item_download_counts_path(units(:buried))
    assert_response :gone
  end

  # item_results()

  test "item_results() returns HTTP 200" do
    get unit_item_results_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  test "item_results() returns HTTP 404 for non-XHR requests" do
    get unit_item_results_path(units(:unit1))
    assert_response :not_found
  end

  test "item_results() returns HTTP 410 for a buried unit" do
    get unit_item_results_path(units(:buried)), xhr: true
    assert_response :gone
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

  test "show() returns HTTP 410 for a buried unit" do
    get unit_path(units(:buried))
    assert_response :gone
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get unit_path(units(:unit1))
    assert_select("#access-tab")

    get unit_path(units(:unit1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # show_access()

  test "show_access() redirects to login page for logged-out users" do
    unit = units(:unit1)
    get unit_access_path(unit), xhr: true
    assert_redirected_to login_path
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    get unit_access_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_access_path(unit)
    assert_response :not_found
  end

  test "show_access() returns HTTP 410 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    get unit_access_path(unit), xhr: true
    assert_response :gone
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    unit = units(:unit1)
    get unit_access_path(unit), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get unit_access_path(units(:unit1)), xhr: true
    assert_select(".edit-administrators")

    get unit_access_path(units(:unit1), role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-administrators", false)
  end

  # show_collections()

  test "show_collections() returns HTTP 200" do
    get unit_collections_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  test "show_collections() returns HTTP 404 for non-XHR requests" do
    get unit_collections_path(units(:unit1))
    assert_response :not_found
  end

  test "show_collections() returns HTTP 410 for a buried unit" do
    get unit_collections_path(units(:buried)), xhr: true
    assert_response :gone
  end

  # show_items()

  test "show_items() returns HTTP 200" do
    get unit_items_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  test "show_items() returns HTTP 404 for non-XHR requests" do
    get unit_items_path(units(:unit1))
    assert_response :not_found
  end

  test "show_items() returns HTTP 410 for a buried unit" do
    get unit_items_path(units(:buried)), xhr: true
    assert_response :gone
  end

  # show_properties()

  test "show_properties() returns HTTP 200" do
    get unit_properties_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  test "show_properties() returns HTTP 404 for non-XHR requests" do
    get unit_properties_path(units(:unit1))
    assert_response :not_found
  end

  test "show_properties() returns HTTP 410 for a buried unit" do
    get unit_properties_path(units(:buried)), xhr: true
    assert_response :gone
  end

  # show_statistics()

  test "show_statistics() returns HTTP 404 for non-XHR requests" do
    get unit_statistics_path(units(:unit1))
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 410 for a buried unit" do
    get unit_statistics_path(units(:buried)), xhr: true
    assert_response :gone
  end

  test "show_statistics() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get unit_statistics_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  # show_units()

  test "show_units() returns HTTP 200" do
    get unit_units_path(units(:unit1)), xhr: true
    assert_response :ok
  end

  test "show_units() returns HTTP 410" do
    get unit_units_path(units(:buried)), xhr: true
    assert_response :gone
  end

  test "show_units() returns HTTP 404 for non-XHR requests" do
    get unit_units_path(units(:unit1))
    assert_response :not_found
  end

  # statistics_by_range()

  test "statistics_by_range() returns HTTP 200 for HTML" do
    log_in_as(users(:local_sysadmin))
    get unit_statistics_by_range_path(units(:unit1))
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 200 for CSV" do
    log_in_as(users(:local_sysadmin))
    get unit_statistics_by_range_path(units(:unit1), format: :csv)
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 410 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    get unit_statistics_by_range_path(units(:buried)), xhr: true
    assert_response :gone
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

  test "update() returns HTTP 410 for a buried unit" do
    log_in_as(users(:local_sysadmin))
    unit = units(:buried)
    patch unit_path(unit)
    assert_response :gone
  end

  test "update() updates a unit" do
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
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
    log_in_as(users(:local_sysadmin))
    patch "/units/bogus"
    assert_response :not_found
  end

end
