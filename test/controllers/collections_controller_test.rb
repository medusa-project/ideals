require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
  end

  teardown do
    log_out
  end

  # chlldren()

  test "children() returns HTTP 404 for non-XHR requests" do
    get collection_children_path(collections(:collection1))
    assert_response :not_found
  end

  test "children() returns HTTP 200 for XHR requests" do
    get collection_children_path(collections(:collection1)), xhr: true
    assert_response :ok
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post collections_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post collections_path,
         xhr: true,
         params: {
             collection: {
                 metadata_profile_id: metadata_profiles(:empty).id
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
             primary_unit_id: units(:unit1).id,
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
               primary_unit_id: units(:unit1).id,
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

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete "/collections/#{collections(:collection1).id}"
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete "/collections/#{collections(:collection1).id}"
    assert_response :forbidden
  end

  test "destroy() destroys the collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:empty)
    delete "/collections/#{collection.id}"
    assert_raises ActiveRecord::RecordNotFound do
      Collection.find(collection.id)
    end
  end

  test "destroy() redirects to the parent collection, if available, for an
  existing collection" do
    log_in_as(users(:local_sysadmin))
    collection   = collections(:collection1_collection1)
    delete collection_path(collection)
    assert_redirected_to collection.parent
  end

  test "destroy() redirects to the primary unit, if there is no parent
  collection, for an existing collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    primary_unit = collection.primary_unit
    delete collection_path(collection)
    assert_redirected_to primary_unit
  end

  test "destroy() returns HTTP 404 for a missing collections" do
    log_in_as(users(:local_sysadmin))
    delete "/collections/bogus"
    assert_response :not_found
  end

  # edit_access()

  test "edit_access() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    get collection_edit_access_path(collection), xhr: true
    assert_redirected_to login_path
  end

  test "edit_access() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get collection_edit_access_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_access() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_access_path(collection)
    assert_response :not_found
  end

  test "edit_access() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_access_path(collection), xhr: true
    assert_response :ok
  end

  # edit_collection_membership()

  test "edit_collection_membership() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_redirected_to login_path
  end

  test "edit_collection_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_collection_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_collection_membership_path(collection)
    assert_response :not_found
  end

  test "edit_collection_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_collection_membership_path(collection), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_properties_path(collection)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_properties_path(collection), xhr: true
    assert_response :ok
  end

  # edit_unit_membership()

  test "edit_unit_membership() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_redirected_to login_path
  end

  test "edit_unit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :forbidden
  end

  test "edit_unit_membership() returns HTTP 200 for non-XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_unit_membership_path(collection)
    assert_response :not_found
  end

  test "edit_unit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_edit_unit_membership_path(collection), xhr: true
    assert_response :ok
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

  test "item_download_counts() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    get collection_item_download_counts_path(collection)
    assert_redirected_to login_path
  end

  test "item_download_counts() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get collection_item_download_counts_path(collection)
    assert_response :forbidden
  end

  test "item_download_counts() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    get collection_item_download_counts_path(collection)
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200 for HTML" do
    get collection_path(collections(:collection1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    get collection_path(collections(:collection1), format: :json)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get collection_path(collections(:collection1))
    assert_select("#access-tab")

    get collection_path(collections(:collection1), role: Role::LOGGED_OUT)
    assert_select("#access-tab", false)
  end

  # statistics()

  test "statistics() redirects to login page for logged-out users" do
    get collection_statistics_path(collections(:collection1)), xhr: true
    assert_redirected_to login_path
  end

  test "statistics() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get collection_statistics_path(collections(:collection1)), xhr: true
    assert_response :forbidden
  end

  test "statistics() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get collection_statistics_path(collections(:collection1)), xhr: true
    assert_response :ok
  end

  # statistics_by_range()

  test "statistics_by_range() redirects to login page for logged-out users" do
    get collection_statistics_by_range_path(collections(:collection1))
    assert_redirected_to login_path
  end

  test "statistics_by_range() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get collection_statistics_by_range_path(collections(:collection1))
    assert_response :forbidden
  end

  test "statistics_by_range() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    get collection_statistics_by_range_path(collections(:collection1))
    assert_response :ok
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    collection = collections(:collection1)
    patch collection_path(collection)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    patch collection_path(collection)
    assert_response :forbidden
  end

  test "update() updates a collection" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
              collection: {
                  metadata_profile_id: metadata_profiles(:empty).id
              },
              elements: {
                  "dc:description": "New description"
              }
          }
    collection.reload
    assert_equal "New description", collection.description
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:collection1)
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
    collection = collections(:collection1)
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
    collection = collections(:collection1_collection1)
    patch collection_path(collection),
          xhr: true,
          params: {
            collection: {
              parent_id: collections(:described).id
            }
          }
    assert_response :forbidden
  end


  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:local_sysadmin))
    patch "/collections/bogus"
    assert_response :not_found
  end

end
