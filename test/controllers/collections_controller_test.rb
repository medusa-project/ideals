require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southeast)
    host! @institution.fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # all_files()

  test "all_files() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_response :not_found
  end

  test "all_files() redirects to root page for logged-out users" do
    collection = collections(:southeast_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_redirected_to collection.institution.scope_url
  end

  test "all_files() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    collection = collections(:southeast_empty)
    get collection_all_files_path(collection, format: :zip)
    assert_response :forbidden
  end

  test "all_files() returns HTTP 415 for an unsupported media type" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_empty)
    get collection_all_files_path(collection)
    assert_response :unsupported_media_type
  end

  test "all_files() redirects to a Download" do
    Item.reindex_all
    refresh_opensearch
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_all_files_path(collection, format: :zip)
    assert_response 302
  end

  # bury()

  test "bury() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    post collection_bury_path(collection)
    assert_response :not_found
  end

  test "bury() redirects to root page for logged-out users" do
    collection = collections(:southeast_collection1)
    post collection_bury_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "bury() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post collection_bury_path(collections(:southeast_collection1))
    assert_response :forbidden
  end

  test "bury() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    post collection_bury_path(collections(:southeast_buried))
    assert_response :gone
  end

  test "bury() buries the collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_empty)
    post collection_bury_path(collection)
    collection.reload
    assert collection.buried
  end

  test "bury() redirects to the collection when the bury fails" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    post collection_bury_path(collection) # fails because collection is not empty
    assert_redirected_to collection
  end

  test "bury() redirects to the parent collection, if available, for an
  existing collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1_collection1_collection1)
    post collection_bury_path(collection)
    assert_redirected_to collection.parent
  end

  test "bury() redirects to the primary unit, if there is no parent
  collection, for an existing collection" do
    log_in_as(users(:southeast_admin))
    collection   = collections(:southeast_empty)
    primary_unit = collection.primary_unit
    post collection_bury_path(collection)
    assert_redirected_to primary_unit
  end

  test "bury() returns HTTP 404 for a missing collections" do
    log_in_as(users(:southeast_admin))
    post "/collections/bogus/bury"
    assert_response :not_found
  end

  # children()

  test "children() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get collection_children_path(collections(:southeast_collection1)), xhr: true
    assert_response :not_found
  end

  test "children() returns HTTP 200 for XHR requests" do
    get collection_children_path(collections(:southeast_collection1)), xhr: true
    assert_response :ok
  end

  test "children() returns HTTP 404 for non-XHR requests" do
    get collection_children_path(collections(:southeast_collection1))
    assert_response :not_found
  end

  test "children() returns HTTP 410 for a buried collection" do
    get collection_children_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post collections_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post collections_path
    assert_redirected_to @institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post collections_path,
         xhr: true,
         params: {
           primary_unit_id: units(:southeast_unit1).id,
           collection: {
             institution_id: @institution.id,
             metadata_profile_id: metadata_profiles(:southeast_empty).id
           },
           elements: {
             title: "New Collection"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:southeast_admin))
    post collections_path,
         xhr: true,
         params: {
           primary_unit_id: units(:southeast_unit1).id,
           collection: {
             institution_id:   @institution.id,
             administrator_id: users(:southwest_sysadmin).id
           },
           elements: {
             title: "New Collection"
           }
         }
    assert_response :ok
  end

  test "create() creates a collection" do
    log_in_as(users(:southeast_admin))
    assert_difference "Collection.count" do
      post collections_path,
           xhr: true,
           params: {
             primary_unit_id: units(:southeast_unit1).id,
             collection: {
               institution_id:   @institution.id,
               administrator_id: users(:southwest_sysadmin).id
             },
             elements: {
               title: "New Collection"
             }
           }
    end
  end

  test "create() creates an Event" do
    log_in_as(users(:southeast_admin))
    assert_difference "Event.count" do
      post collections_path,
           xhr: true,
           params: {
             primary_unit_id: units(:southeast_unit1).id,
             collection: {
               institution_id:   @institution.id,
               administrator_id: users(:southwest_sysadmin).id
             },
             elements: {
               title: "New Collection"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southeast_admin))
    post collections_path,
         xhr: true,
         params: {
           collection: {
             metadata_profile_id: 99999
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    delete collection_path(collection)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    collection = collections(:southeast_collection1)
    delete collection_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    delete collection_path(collections(:southeast_collection1))
    assert_response :forbidden
  end

  test "destroy() destroys the collection" do
    log_in_as(users(:southeast_sysadmin))
    collection = collections(:southeast_empty)
    delete collection_path(collection)
    assert_raises ActiveRecord::RecordNotFound do
      collection.reload
    end
  end

  test "destroy() redirects to the collection when the destroy fails" do
    log_in_as(users(:southeast_sysadmin))
    collection = collections(:southeast_collection1)
    delete collection_path(collection) # fails because collection is not empty
    assert_redirected_to collection
  end

  test "destroy() redirects to the parent collection, if available, for an
  existing collection" do
    log_in_as(users(:southeast_sysadmin))
    collection = collections(:southeast_collection1_collection1_collection1)
    delete collection_path(collection)
    assert_redirected_to collection.parent
  end

  test "destroy() redirects to the primary unit, if there is no parent
  collection, for an existing collection" do
    log_in_as(users(:southeast_sysadmin))
    collection   = collections(:southeast_empty)
    primary_unit = collection.primary_unit
    delete collection_path(collection)
    assert_redirected_to primary_unit
  end

  test "destroy() returns HTTP 404 for a missing collections" do
    log_in_as(users(:southeast_sysadmin))
    delete "/collections/bogus"
    assert_response :not_found
  end

  # edit_collection_membership()

  test "edit_collection_membership() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_collection_membership() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_collection_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_collection_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_collection_membership_path(collection)
    assert_response :not_found
  end

  test "edit_collection_membership() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_collection_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :ok
  end

  # edit_administering_groups()

  test "edit_administering_groups() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_administering_groups_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_administering_groups_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_groups_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_groups() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_groups_path(collection)
    assert_response :not_found
  end

  test "edit_administering_groups() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_administering_groups_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_administering_groups() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_groups_path(collection), xhr: true
    assert_response :ok
  end

  # edit_administering_users()

  test "edit_administering_users() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_administering_users_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_administering_users_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_users_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_administering_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_users_path(collection)
    assert_response :not_found
  end

  test "edit_administering_users() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_administering_users_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_administering_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_administering_users_path(collection), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_properties_path(collection)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :ok
  end

  # edit_submitting_groups()

  test "edit_submitting_groups() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_groups_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_submitting_groups() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_groups_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitting_groups() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_groups_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitting_groups() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_groups_path(collection)
    assert_response :not_found
  end

  test "edit_submitting_groups() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_submitting_groups_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_submitting_groups() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_groups_path(collection), xhr: true
    assert_response :ok
  end

  # edit_submitting_users()

  test "edit_submitting_users() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_users_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_submitting_users() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_users_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitting_users() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_users_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_submitting_users() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_users_path(collection)
    assert_response :not_found
  end

  test "edit_submitting_users() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_submitting_users_path(collection), xhr: true
    assert_response :gone
  end

  test "edit_submitting_users() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_submitting_users_path(collection), xhr: true
    assert_response :ok
  end

  # edit_unit_membership()

  test "edit_unit_membership() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :not_found
  end

  test "edit_unit_membership() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_unit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :ok
  end

  test "edit_unit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_unit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_edit_unit_membership_path(collection)
    assert_response :not_found
  end

  test "edit_unit_membership() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :gone
  end

  # exhume()

  test "exhume() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_buried)
    post collection_exhume_path(collection)
    assert_response :not_found
  end

  test "exhume() redirects to root page for logged-out users" do
    collection = collections(:southeast_buried)
    post collection_exhume_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "exhume() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post collection_exhume_path(collections(:southeast_buried))
    assert_response :forbidden
  end

  test "exhume() exhumes the collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    collection.units.first.exhume!
    post collection_exhume_path(collection)
    collection.reload
    assert !collection.buried
  end

  test "exhume() redirects to the collection when the exhume fails" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    post collection_exhume_path(collection) # fails because collection is not empty
    assert_redirected_to collection
  end

  test "exhume() redirects to the collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_buried)
    post collection_exhume_path(collection)
    assert_redirected_to collection
  end

  test "exhume() returns HTTP 404 for a missing collections" do
    log_in_as(users(:southeast_admin))
    post "/collections/bogus/exhume"
    assert_response :not_found
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get collections_path
    assert_response :not_found
  end

  test "index() returns HTTP 406 for HTML" do
    get collections_path
    assert_response :not_acceptable
  end

  test "index() returns HTTP 200 for JSON" do
    get collections_path(format: :json)
    assert_response :ok
  end

  # item_download_counts()

  test "item_download_counts() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_item_download_counts_path(collection)
    assert_response :not_found
  end

  test "item_download_counts() returns HTTP 200 for HTML" do
    collection = collections(:southeast_collection1)
    get collection_item_download_counts_path(collection)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 200 for CSV" do
    collection = collections(:southeast_collection1)
    get collection_item_download_counts_path(collection, format: :csv)
    assert_response :ok
  end

  test "item_download_counts() returns HTTP 410 for a buried collection" do
    collection = collections(:southeast_buried)
    get collection_item_download_counts_path(collection)
    assert_response :gone
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_collection_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_collection_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    get new_collection_path(primary_unit_id: 0,
                            collection:      { institution_id: 0 })
    assert_response :forbidden
  end

  test "new() returns HTTP 400 for a missing institution_id argument" do
    log_in_as(users(:southeast_admin))
    get new_collection_path(primary_unit_id: units(:southeast_unit1).id)
    assert_response :bad_request
  end

  test "new() returns HTTP 400 for a missing primary_unit_id argument" do
    log_in_as(users(:southeast_admin))
    get new_collection_path(collection: { institution_id: institutions(:southeast).id })
    assert_response :bad_request
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southeast_admin))
    get new_collection_path(primary_unit_id: units(:southeast_unit1).id,
                            collection: { institution_id: institutions(:southeast).id })
    assert_response :ok
  end

  # show_item_results()

  test "show_item_results() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get collection_item_results_path(collections(:southeast_collection1)), xhr: true
    assert_response :not_found
  end

  test "show_item_results() returns HTTP 200" do
    get collection_item_results_path(collections(:southeast_collection1)), xhr: true
    assert_response :ok
  end

  test "show_item_results() returns HTTP 404 for non-XHR requests" do
    get collection_item_results_path(collections(:southeast_collection1))
    assert_response :not_found
  end

  test "show_item_results() returns HTTP 410 for a buried collection" do
    get collection_item_results_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get collection_path(collections(:southeast_collection1))
    assert_response :not_found
  end

  test "show() returns HTTP 200 for HTML" do
    get collection_path(collections(:southeast_collection1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    get collection_path(collections(:southeast_collection1), format: :json)
    assert_response :ok
  end

  test "show() redirects for a collection in another institution for
  non-sysadmins" do
    collection = collections(:southwest_unit1_collection1)
    get collection_path(collection)
    assert_redirected_to "http://" + collection.institution.fqdn +
                           collection_path(collection)
  end

  test "show() does not redirect for a collection in another institution for
  sysadmins" do
    log_in_as(users(:southeast_sysadmin))
    collection = collections(:southwest_unit1_collection1)
    get collection_path(collection)
    assert_response :ok
  end

  test "show() returns HTTP 410 for a buried collection" do
    get collection_path(collections(:southeast_buried))
    assert_response :gone
  end

  test "show() respects role limits" do
    log_in_as(users(:southeast_admin))
    get collection_path(collections(:southeast_collection1))
    assert_select("#access-tab")

    get collection_path(collections(:southeast_collection1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # show_about()

  test "show_about() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_about_path(collection)
    assert_response :not_found
  end

  test "show_about() returns HTTP 404 for non-XHR requests" do
    collection = collections(:southeast_collection1)
    get collection_about_path(collection)
    assert_response :not_found
  end

  test "show_about() returns HTTP 200 for XHR requests" do
    collection = collections(:southeast_collection1)
    get collection_about_path(collection), xhr: true
    assert_response :ok
  end

  test "show_about() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southwest_sysadmin))
    get collection_about_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  # show_access()

  test "show_access() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :not_found
  end

  test "show_access() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_access_path(collection)
    assert_response :not_found
  end

  test "show_access() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    get collection_access_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  test "show_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_access_path(collection), xhr: true
    assert_response :ok
  end

  test "show_access() respects role limits" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_access_path(collection), xhr: true
    assert_select(".edit-administering-groups")

    get collection_access_path(collection, role: Role::LOGGED_OUT), xhr: true
    assert_select(".edit-administering-groups", false)
  end

  # show_items()

  test "show_items() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_items_path(collection)
    assert_response :not_found
  end

  test "show_items() returns HTTP 200 for HTML" do
    collection = collections(:southeast_collection1)
    get collection_items_path(collection)
    assert_response :ok
  end

  test "show_items() returns HTTP 403 for CSV for non-unit-administrators" do
    collection = collections(:southeast_collection1)
    get collection_items_path(collection, format: :csv)
    assert_response :forbidden
  end

  test "show_items() returns HTTP 200 for CSV for unit administrators" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_items_path(collection, format: :csv)
    assert_response :ok
  end

  test "show_items() returns HTTP 410 for a buried collection" do
    collection = collections(:southeast_buried)
    get collection_items_path(collection)
    assert_response :gone
  end

  # show_review_submissions()

  test "show_review_submissions() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_review_submissions_path(collection), xhr: true
    assert_response :not_found
  end

  test "show_review_submissions() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_review_submissions_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_review_submissions_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_review_submissions() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_review_submissions_path(collection)
    assert_response :not_found
  end

  test "show_review_submissions() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    get collection_review_submissions_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  test "show_review_submissions() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_review_submissions_path(collection), xhr: true
    assert_response :ok
  end

  # show_statistics()

  test "show_statistics() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_statistics_path(collection)
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 200" do
    get collection_statistics_path(collections(:southeast_collection1)), xhr: true
    assert_response :ok
  end

  test "show_statistics() returns HTTP 404 for non-XHR requests" do
    get collection_statistics_path(collections(:southeast_collection1))
    assert_response :not_found
  end

  test "show_statistics() returns HTTP 410 for a buried collection" do
    get collection_statistics_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  # show_submissions_in_progress()

  test "show_submissions_in_progress() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_submissions_in_progress_path(collection), xhr: true
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 403 for logged-out users" do
    collection = collections(:southeast_collection1)
    get collection_submissions_in_progress_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    collection = collections(:southeast_collection1)
    get collection_submissions_in_progress_path(collection), xhr: true
    assert_response :forbidden
  end

  test "show_submissions_in_progress() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    collection = collections(:southeast_collection1)
    get collection_submissions_in_progress_path(collection)
    assert_response :not_found
  end

  test "show_submissions_in_progress() returns HTTP 410 for a buried collection" do
    log_in_as(users(:southeast_admin))
    get collection_submissions_in_progress_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

  test "show_submissions_in_progress() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    get collection_submissions_in_progress_path(collection), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    get collection_statistics_by_range_path(collection)
    assert_response :not_found
  end

  test "statistics_by_range() returns HTTP 200 for HTML" do
    collection = collections(:southeast_collection1)
    get collection_statistics_by_range_path(collection), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 200 for CSV" do
    collection = collections(:southeast_collection1)
    get collection_statistics_by_range_path(collection, format: :csv), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2008,
      to_month:   12
    }
    assert_response :ok
  end

  test "statistics_by_range() returns HTTP 400 for illegal arguments" do
    collection = collections(:southeast_collection1)
    get collection_statistics_by_range_path(collection), params: {
      from_year:  2008,
      from_month: 1,
      to_year:    2006,
      to_month:   12
    }
    assert_response :bad_request
  end

  test "statistics_by_range() returns HTTP 410 for a buried collection" do
    get collection_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end
  
  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    collection = collections(:southeast_collection1)
    patch collection_path(collection)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    collection = collections(:southeast_collection1)
    patch collection_path(collection)
    assert_redirected_to collection.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    collection = collections(:southeast_collection1)
    patch collection_path(collection)
    assert_response :forbidden
  end

  test "update() updates a collection" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
            collection: {
              description: "New description",
              metadata_profile_id: metadata_profiles(:southeast_empty).id
            }
          }
    collection.reload
    assert_equal "New description", collection.description
  end

  test "update() creates an Event" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    assert_difference "Event.count" do
      patch collection_path(collection),
            xhr: true,
            params: {
              collection: {
                description: "New description",
                metadata_profile_id: metadata_profiles(:southeast_empty).id
              }
            }
    end
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
            collection: {
              administering_user_ids: [ users(:southwest_sysadmin).id ]
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southeast_admin))
    collection = collections(:southeast_collection1)
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
  collection of which the current user is not an effective administrator" do
    log_in_as(users(:southeast_collection1_collection1_admin))
    collection = collections(:southeast_collection1_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
            collection: {
              parent_id: collections(:southeast_described).id
            }
          }
    assert_response :forbidden
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:southeast_admin))
    patch "/collections/bogus"
    assert_response :not_found
  end

  test "update() returns HTTP 410 for a buried collections" do
    log_in_as(users(:southeast_admin))
    patch collection_path(collections(:southeast_buried)), xhr: true
    assert_response :gone
  end

end
