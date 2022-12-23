require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_opensearch
  end

  teardown do
    log_out
  end

  # all_files()

  test "all_files() redirects to root page for logged-out users" do
    collection = collections(:uiuc_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_redirected_to collection.institution.scope_url
  end

  test "all_files() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_response :forbidden
  end

  test "all_files() returns HTTP 415 for an unsupported media type" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_empty)
    get collection_all_files_path(collection)
    assert_response :unsupported_media_type
  end

  test "all_files() with no results returns HTTP 204" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_response :no_content
  end

  test "all_files() redirects to a Download" do
    Item.reindex_all
    refresh_opensearch
    log_in_as(users(:uiuc_admin))
    collection = collections(:uiuc_collection1)
    get collection_all_files_path(collection, format: :zip)
    assert_response 302
  end

  # children()

  test "children() returns HTTP 200 for XHR requests" do
    get collection_children_path(collections(:uiuc_collection1)), xhr: true
    assert_response :ok
  end

  test "children() returns HTTP 404 for non-XHR requests" do
    get collection_children_path(collections(:uiuc_collection1))
    assert_response :not_found
  end

  test "children() returns HTTP 410 for a buried collection" do
    get collection_children_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # create()

  test "create() redirects to root page for logged-out users" do
    post collections_path
    assert_redirected_to Institution.default.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post collections_path,
         xhr: true,
         params: {
             primary_unit_id: units(:uiuc_unit1).id,
             collection: {
                 metadata_profile_id: metadata_profiles(:uiuc_empty).id
             },
             elements: {
                 title: "New Collection"
             }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    post collections_path,
         xhr: true,
         params: {
             primary_unit_id: units(:uiuc_unit1).id,
             collection: {
                 manager_id: users(:local_sysadmin).id
             },
             elements: {
                 title: "New Collection"
             }
         }
    assert_response :ok
  end

  test "create() creates a collection" do
    log_in_as(users(:local_sysadmin))
    assert_difference "Collection.count" do
      post collections_path,
           xhr: true,
           params: {
               primary_unit_id: units(:uiuc_unit1).id,
               collection: {
                   manager_id: users(:local_sysadmin).id
               },
               elements: {
                   title: "New Collection"
               }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post collections_path,
         xhr: true,
         params: {
             collection: {
                 metadata_profile_id: 99999
             }
         }
    assert_response :bad_request
  end

  # delete()

  test "delete() redirects to root page for logged-out users" do
    collection = collections(:uiuc_collection1)
    post collection_delete_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "delete() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post collection_delete_path(collections(:uiuc_collection1))
    assert_response :forbidden
  end

  test "delete() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    post collection_delete_path(collections(:uiuc_buried))
    assert_response :gone
  end

  test "delete() buries the collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_empty)
    post collection_delete_path(collection)
    collection.reload
    assert collection.buried
  end

  test "delete() redirects to the collection when the delete fails" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    post collection_delete_path(collection) # fails because collection is not empty
    assert_redirected_to collection
  end

  test "delete() redirects to the parent collection, if available, for an
  existing collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1_collection1_collection1)
    post collection_delete_path(collection)
    assert_redirected_to collection.parent
  end

  test "delete() redirects to the primary unit, if there is no parent
  collection, for an existing collection" do
    log_in_as(users(:local_sysadmin))
    collection   = collections(:uiuc_empty)
    primary_unit = collection.primary_unit
    post collection_delete_path(collection)
    assert_redirected_to primary_unit
  end

  test "delete() returns HTTP 404 for a missing collections" do
    log_in_as(users(:local_sysadmin))
    post "/collections/bogus/delete"
    assert_response :not_found
  end

  # edit_collection_membership()

  test "edit_collection_membership() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_collection_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_collection_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_collection_membership_path(collection)
    assert_response :not_found
  end

  test "edit_collection_membership() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_collection_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :ok
  end

  # edit_managers()

  test "edit_managers() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_edit_managers_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_managers() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_edit_managers_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_managers() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_managers_path(collection)
    assert_response :not_found
  end

  test "edit_managers() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    get collection_edit_managers_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_managers() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_managers_path(collection), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_properties_path(collection)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :ok
  end

  # edit_submitters()

  test "edit_submitters() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_edit_submitters_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitters() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_edit_submitters_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitters() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_submitters_path(collection)
    assert_response :not_found
  end

  test "edit_submitters() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    get collection_edit_submitters_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_submitters() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_submitters_path(collection), xhr: true
    assert_response :ok
  end

  # edit_unit_membership()

  test "edit_unit_membership() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_unit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :ok
  end

  test "edit_unit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_unit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_edit_unit_membership_path(collection)
    assert_response :not_found
  end

  test "edit_unit_membership() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :gone
  end

  # index()

  test "index() returns HTTP 406 for HTML" do
    get collections_path
    assert_response :not_acceptable
  end

  test "index() returns HTTP 200 for JSON" do
    get collections_path(format: :json)
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() returns HTTP 200 for HTML" do
    collection = collections(:uiuc_collection1)
    get collection_item_download_counts_path(collection)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 200 for CSV" do
    collection = collections(:uiuc_collection1)
    get collection_item_download_counts_path(collection, format: :csv)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 410 for a buried collection" do
    collection = collections(:uiuc_buried)
    get collection_item_download_counts_path(collection)
    assert_response :gone
  end

  # show_item_results()

  test "show_item_results() returns HTTP 200" do
    get collection_item_results_path(collections(:uiuc_collection1)), xhr: true
    assert_response :ok
  end

  test "show_item_results() returns HTTP 404 for non-XHR requests" do
    get collection_item_results_path(collections(:uiuc_collection1))
    assert_response :not_found
  end

  test "show_item_results() returns HTTP 410 for a buried collection" do
    get collection_item_results_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # show()

  test "show() returns HTTP 200 for HTML" do
    get collection_path(collections(:uiuc_collection1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    get collection_path(collections(:uiuc_collection1), format: :json)
    assert_response :ok
  end

  test "show() returns HTTP 410 for a buried collection" do
    get collection_path(collections(:uiuc_buried))
    assert_response :gone
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get collection_path(collections(:uiuc_collection1))
    assert_select("#access-tab")

    get collection_path(collections(:uiuc_collection1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # show_about()

  test "show_about() returns HTTP 404 for non-XHR requests" do
    collection = collections(:uiuc_collection1)
    get collection_about_path(collection)
    assert_response :not_found
  end

  test "show_about() returns HTTP 200 for XHR requests" do
    collection = collections(:uiuc_collection1)
    get collection_about_path(collection), xhr: true
    assert_response :ok
  end

  test "show_about() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    get collection_about_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # show_access()

  test "show_access() returns HTTP 403 for logged-out users" do
    collection = collections(:uiuc_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_access_path(collection)
    assert_response :not_found
  end

  test "show_access() returns HTTP 410 for a buried collection" do
    log_in_as(users(:local_sysadmin))
    get collection_access_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    get collection_access_path(collection), xhr: true
    assert_select(".edit-collection-managers")

    get collection_access_path(collection, role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-collection-managers", false)
  end

  # show_items()

  test "show_items() returns HTTP 200 for HTML" do
    get collection_items_path(collections(:uiuc_collection1))
    assert_response :ok
  end

  test "show_items() returns HTTP 403 for CSV for non-unit-administrators" do
    get collection_items_path(collections(:uiuc_collection1), format: :csv)
    assert_response :forbidden
  end

  test "show_items() returns HTTP 200 for CSV for unit administrators" do
    log_in_as(users(:local_sysadmin))
    get collection_items_path(collections(:uiuc_collection1), format: :csv)
    assert_response :ok
  end

  test "show_items() returns HTTP 410 for a buried collection" do
    get collection_items_path(collections(:uiuc_buried))
    assert_response :gone
  end

  # show_statistics()

  test "show_statistics() returns HTTP 200" do
    get collection_statistics_path(collections(:uiuc_collection1)), xhr: true
    assert_response :ok
  end

  test "show_statistics() returns HTTP 404 for non-XHR requests" do
    get collection_statistics_path(collections(:uiuc_collection1))
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 410 for a buried collection" do
    get collection_statistics_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # statistics_by_range()

  test "statistics_by_range() returns HTTP 200 for HTML" do
    collection = collections(:uiuc_collection1)
    get collection_statistics_by_range_path(collection), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 200 for CSV" do
    collection = collections(:uiuc_collection1)
    get collection_statistics_by_range_path(collection, format: :csv), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 410 for a buried collection" do
    get collection_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

  # undelete()

  test "undelete() redirects to root page for logged-out users" do
    collection = collections(:uiuc_buried)
    post collection_undelete_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "undelete() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post collection_undelete_path(collections(:uiuc_buried))
    assert_response :forbidden
  end

  test "undelete() exhumes the collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    collection.units.first.exhume!
    post collection_undelete_path(collection)
    collection.reload
    assert !collection.buried
  end

  test "undelete() redirects to the collection when the undelete fails" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    post collection_undelete_path(collection) # fails because collection is not empty
    assert_redirected_to collection
  end

  test "undelete() redirects to the collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_buried)
    post collection_undelete_path(collection)
    assert_redirected_to collection
  end

  test "undelete() returns HTTP 404 for a missing collections" do
    log_in_as(users(:local_sysadmin))
    post "/collections/bogus/undelete"
    assert_response :not_found
  end

  # update()

  test "update() redirects to root page for logged-out users" do
    collection = collections(:uiuc_collection1)
    patch collection_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:uiuc_collection1)
    patch collection_path(collection)
    assert_response :forbidden
  end

  test "update() updates a collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
              collection: {
                  description: "New description",
                  metadata_profile_id: metadata_profiles(:uiuc_empty).id
              }
          }
    collection.reload
    assert_equal "New description", collection.description
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
              collection: {
                  managing_user_ids: [ users(:local_sysadmin).id ]
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
              collection: {
                  metadata_profile_id: 99999
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 403 when updating the collection parent_id to a
  collection of which the current user is not an effective manager" do
    log_in_as(users(:collection1_collection1_manager))
    collection = collections(:uiuc_collection1_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
            collection: {
              parent_id: collections(:uiuc_described).id
            }
          }
    assert_response :forbidden
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:local_sysadmin))
    patch "/collections/bogus"
    assert_response :not_found
  end

  test "update() returns HTTP 410 for a buried collections" do
    log_in_as(users(:local_sysadmin))
    patch collection_path(collections(:uiuc_buried)), xhr: true
    assert_response :gone
  end

end
