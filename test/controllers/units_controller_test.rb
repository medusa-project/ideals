require 'test_helper'

class UnitsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:uiuc)
    host! @institution.fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # children()

  test "children() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_children_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "children() returns HTTP 404 for non-XHR requests" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_children_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "children() returns HTTP 410 for a buried unit" do
    get unit_children_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "children() returns HTTP 200 for XHR requests" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_children_path(units(:uiuc_unit1)), xhr: true
    assert_response :ok
  end

  # collections_tree_fragment()

  test "collections_tree_fragment() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_collections_tree_fragment_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "collections_tree_fragment() returns HTTP 404 for non-XHR requests" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_collections_tree_fragment_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "collections_tree_fragment() returns HTTP 410 for a buried unit" do
    get unit_collections_tree_fragment_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "collections_tree_fragment() returns HTTP 200 for XHR requests" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_collections_tree_fragment_path(units(:uiuc_unit1)), xhr: true
    assert_response :ok
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post units_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post units_path
    assert_redirected_to @institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
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

  test "create() creates an Event" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "Event.count" do
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
    user = users(:uiuc_admin)
    log_in_as(user)
    post units_path,
         xhr: true,
         params: {
           unit: {
             institution_id: user.institution.id,
             title:          "" # invalid
           }
         }
    assert_response :bad_request
  end

  # delete()

  test "delete() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    post unit_delete_path(unit)
    assert_response :not_found
  end

  test "delete() redirects to root page for logged-out users" do
    unit = units(:uiuc_unit1)
    post unit_delete_path(unit)
    assert_redirected_to unit.institution.scope_url
  end

  test "delete() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    post unit_delete_path(unit)
    assert_response :forbidden
  end

  test "delete() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    post unit_delete_path(unit)
    assert_response :gone
  end

  test "delete() buries the unit" do
    log_in_as(users(:uiuc_admin))
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:uiuc_empty)
    post unit_delete_path(unit)
    unit.reload
    assert unit.buried
  end

  test "delete() redirects to the unit when the delete fails" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    post unit_delete_path(unit)
    assert_redirected_to unit_path(unit)
  end

  test "delete() redirects to the parent unit, if available, when the delete
  succeeds" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1_unit1)
    post unit_delete_path(unit)
    assert_redirected_to unit_path(unit.parent)
  end

  test "delete() redirects to the units path if the unit is in the current
  institution's scope and there is no parent unit and the delete succeeds" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_empty)
    post unit_delete_path(unit)
    assert_redirected_to units_path
  end

  test "delete() redirects to the owning institution if the unit is in a
  different institution than the current institution's scope and there is no
  parent unit and the delete succeeds" do
    log_in_as(users(:uiuc_sysadmin))
    unit = units(:southwest_unit2)
    post unit_delete_path(unit)
    assert_redirected_to institution_path(unit.institution)
  end

  test "delete() returns HTTP 404 for a missing unit" do
    log_in_as(users(:uiuc_admin))
    post "/units/bogus/delete"
    assert_response :not_found
  end

  # edit_administering_groups()

  test "edit_administering_groups() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_edit_administering_groups_path(unit), xhr: true
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_edit_administering_groups_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_groups_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_groups_path(unit)
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    get unit_edit_administering_groups_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_administering_groups() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_groups_path(unit), xhr: true
    assert_response :ok
  end

  # edit_administering_users()

  test "edit_administering_users() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_edit_administering_users_path(unit), xhr: true
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_edit_administering_users_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_users_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_users_path(unit)
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    get unit_edit_administering_users_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_administering_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_administering_users_path(unit), xhr: true
    assert_response :ok
  end

  # edit_membership()

  test "edit_membership() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_membership_path(unit)
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 404 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_membership_path(unit), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    unit = units(:uiuc_unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_properties_path(unit)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 404 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :gone
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_edit_properties_path(unit), xhr: true
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get units_path
    assert_response :not_found
  end

  test "index() returns HTTP 200 for HTML" do
    get units_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for JSON" do
    get units_path(format: :json)
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_item_download_counts_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "item_download_counts() returns HTTP 200 for HTML" do
    get unit_item_download_counts_path(units(:uiuc_unit1))
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 200 for CSV" do
    get unit_item_download_counts_path(units(:uiuc_unit1), format: :csv)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 410 for a buried unit" do
    get unit_item_download_counts_path(units(:uiuc_buried))
    assert_response :gone
  end

  # item_results()

  test "item_results() returns HTTP 200" do
    get unit_item_results_path(units(:uiuc_unit1)), xhr: true
    assert_response :ok
  end

  test "item_results() returns HTTP 404 for non-XHR requests" do
    get unit_item_results_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "item_results() returns HTTP 410 for a buried unit" do
    get unit_item_results_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_unit_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_unit_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    user = users(:uiuc)
    log_in_as(user)
    get new_unit_path(unit: { institution_id: user.institution.id })
    assert_response :forbidden
  end

  test "new() returns HTTP 400 for a missing institution_id argument" do
    log_in_as(users(:uiuc_admin))
    get new_unit_path
    assert_response :bad_request
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_unit_path(unit: { institution_id: institutions(:uiuc).id })
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show() returns HTTP 200 for HTML" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_path(units(:uiuc_unit1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    collections(:uiuc_described).reindex # this is needed to fully initialize the schema
    get unit_path(units(:uiuc_unit1), format: :json)
    assert_response :ok
  end

  test "show() redirects for a unit in another institution for non-sysadmins" do
    unit = units(:southwest_unit1)
    get unit_path(unit)
    assert_redirected_to "http://" + unit.institution.fqdn + unit_path(unit)
  end

  test "show() does not redirect for a unit in another institution for
  sysadmins" do
    log_in_as(users(:uiuc_sysadmin))
    unit = units(:southwest_unit1)
    get unit_path(unit)
    assert_response :ok
  end

  test "show() returns HTTP 410 for a buried unit" do
    get unit_path(units(:uiuc_buried))
    assert_response :gone
  end

  test "show() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get unit_path(units(:uiuc_unit1))
    assert_select("#access-tab")

    get unit_path(units(:uiuc_unit1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # show_about()

  test "show_about() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_about_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show_about() returns HTTP 404 for non-XHR requests" do
    get unit_about_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show_about() returns HTTP 200 for XHR requests" do
    get unit_about_path(units(:uiuc_unit1)), xhr: true
    assert_response :ok
  end

  test "show_about() returns HTTP 410 for a buried unit" do
    get unit_about_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # show_access()

  test "show_access() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_access_path(unit), xhr: true
    assert_response :not_found
  end

  test "show_access() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_access_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    get unit_access_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_access_path(unit)
    assert_response :not_found
  end

  test "show_access() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    get unit_access_path(unit), xhr: true
    assert_response :gone
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_access_path(unit), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get unit_access_path(units(:uiuc_unit1)), xhr: true
    assert_select(".edit-administering-users")

    get unit_access_path(units(:uiuc_unit1), role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-administering-users", false)
  end

  # show_items()

  test "show_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_items_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show_items() returns HTTP 200 for HTML" do
    get unit_items_path(units(:uiuc_unit1))
    assert_response :ok
  end

  test "show_items() returns HTTP 403 for CSV for non-unit-administrators" do
    get unit_items_path(units(:uiuc_unit1), format: :csv)
    assert_response :forbidden
  end

  test "show_items() returns HTTP 200 for CSV for unit administrators" do
    log_in_as(users(:uiuc_admin))
    get unit_items_path(units(:uiuc_unit1), format: :csv)
    assert_response :ok
  end

  test "show_items() returns HTTP 410 for a buried unit" do
    get unit_items_path(units(:uiuc_buried))
    assert_response :gone
  end

  # show_review_submissions()

  test "show_review_submissions() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_review_submissions_path(unit), xhr: true
    assert_response :not_found
  end

  test "show_review_submissions() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_review_submissions_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    unit = units(:uiuc_unit1)
    get unit_review_submissions_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    unit = units(:uiuc_unit1)
    get unit_review_submissions_path(unit)
    assert_response :not_found
  end

  test "show_review_submissions() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    get unit_review_submissions_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "show_review_submissions() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_review_submissions_path(unit), xhr: true
    assert_response :ok
  end

  # show_statistics()

  test "show_statistics() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_statistics_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 404 for non-XHR requests" do
    get unit_statistics_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 410 for a buried unit" do
    get unit_statistics_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "show_statistics() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    get unit_statistics_path(units(:uiuc_unit1)), xhr: true
    assert_response :ok
  end

  # show_submissions_in_progress()

  test "show_submissions_in_progress() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    get unit_submissions_in_progress_path(unit), xhr: true
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 403 for logged-out users" do
    unit = units(:uiuc_unit1)
    get unit_submissions_in_progress_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    unit = units(:uiuc_unit1)
    get unit_submissions_in_progress_path(unit), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    unit = units(:uiuc_unit1)
    get unit_submissions_in_progress_path(unit)
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 410 for a buried collection" do
    log_in_as(users(:uiuc_admin))
    get unit_submissions_in_progress_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "show_submissions_in_progress() returns HTTP 200 for XHR requests" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    get unit_submissions_in_progress_path(unit), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get unit_statistics_by_range_path(units(:uiuc_unit1))
    assert_response :not_found
  end

  test "statistics_by_range() returns HTTP 200 for HTML" do
    log_in_as(users(:uiuc_admin))
    get unit_statistics_by_range_path(units(:uiuc_unit1)), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 200 for CSV" do
    log_in_as(users(:southwest_sysadmin))
    get unit_statistics_by_range_path(units(:uiuc_unit1), format: :csv), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
    get unit_statistics_by_range_path(units(:uiuc_unit1)), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2005,
      to_month:   12
    }
    assert_response :bad_request
  end

  test "statistics_by_range() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    get unit_statistics_by_range_path(units(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # undelete()

  test "undelete() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    post unit_undelete_path(unit)
    assert_response :not_found
  end

  test "undelete() redirects to root page for logged-out users" do
    unit = units(:uiuc_unit1)
    post unit_undelete_path(unit)
    assert_redirected_to unit.institution.scope_url
  end

  test "undelete() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    post unit_undelete_path(unit)
    assert_response :forbidden
  end

  test "undelete() exhumes the unit" do
    log_in_as(users(:uiuc_admin))
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:uiuc_buried)
    post unit_undelete_path(unit)
    unit.reload
    assert !unit.buried
  end

  test "undelete() redirects to the unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1_unit1)
    post unit_undelete_path(unit)
    assert_redirected_to unit
  end

  test "undelete() returns HTTP 404 for a missing unit" do
    log_in_as(users(:uiuc_admin))
    post "/units/bogus/undelete"
    assert_response :not_found
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    unit = units(:uiuc_unit1)
    patch unit_path(unit)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    unit = units(:uiuc_unit1)
    patch unit_path(unit)
    assert_redirected_to unit.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:uiuc))
    unit = units(:uiuc_unit1)
    patch unit_path(unit)
    assert_response :forbidden
  end

  test "update() returns HTTP 403 when updating the unit parent_id to a unit of
  which the current user is not an effective administrator" do
    log_in_as(users(:uiuc_unit1_admin))
    unit = units(:uiuc_unit1)
    unit.update!(primary_administrator: nil)
    patch unit_path(unit),
          xhr: true,
          params: {
            unit: {
              parent_id: units(:uiuc_unit2).id
            }
          }
    assert_response :forbidden
  end

  test "update() returns HTTP 410 for a buried unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_buried)
    patch unit_path(unit)
    assert_response :gone
  end

  test "update() updates a unit" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
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

  test "update() creates an Event" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
    assert_difference "Event.count" do
      patch unit_path(unit),
            xhr: true,
            params: {
              unit: {
                title: "cats"
              }
            }
    end
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
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
    log_in_as(users(:uiuc_admin))
    unit = units(:uiuc_unit1)
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
    log_in_as(users(:uiuc_admin))
    patch "/units/bogus"
    assert_response :not_found
  end

end
