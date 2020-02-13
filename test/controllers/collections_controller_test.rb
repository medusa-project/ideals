require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post collections_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post collections_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    post collections_path, {
        xhr: true,
        params: {
            collection: {
                manager_id: users(:admin).id,
                primary_unit_id: units(:unit1).id
            },
            elements: {
                title: "New Collection"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a collection" do
    log_in_as(users(:admin))
    assert_difference "Collection.count" do
      post collections_path, {
          xhr: true,
          params: {
              collection: {
                  manager_id: users(:admin).id,
                  primary_unit_id: units(:unit1).id
              },
              elements: {
                  title: "New Collection"
              }
          }
      }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post collections_path, {
        xhr: true,
        params: {
            collection: {
                primary_unit_id: 99999
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/collections/#{collections(:collection1).id}"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/collections/#{collections(:collection1).id}"
    assert_redirected_to login_path
  end

  test "destroy() destroys the collection" do
    log_in_as(users(:admin))
    collection = collections(:empty)
    delete "/collections/#{collection.id}"
    assert_raises ActiveRecord::RecordNotFound do
      Collection.find(collection.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing collection" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    primary_unit = collection.primary_unit
    delete "/collections/#{collection.id}"
    assert_redirected_to primary_unit
  end

  test "destroy() returns HTTP 404 for a missing collectiont" do
    log_in_as(users(:admin))
    delete "/collections/bogus"
    assert_response :not_found
  end

  # edit_access()

  test "edit_access() redirects to login path for logged-out users" do
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-access", {}
    assert_redirected_to login_path
  end

  test "edit_access() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-access", {}
    assert_redirected_to login_path
  end

  test "edit_access() returns HTTP 200" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-access"
    assert_response :ok
  end

  # edit_membership()

  test "edit_membership() redirects to login path for logged-out users" do
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-membership", {}
    assert_redirected_to login_path
  end

  test "edit_membership() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-membership", {}
    assert_redirected_to login_path
  end

  test "edit_membership() returns HTTP 200" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-membership"
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() redirects to login path for logged-out users" do
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-properties", {}
    assert_redirected_to login_path
  end

  test "edit_properties() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    get "/collections/#{collection.id}/edit-properties", {}
    assert_redirected_to login_path
  end

  test "edit_properties() returns HTTP 200" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    get collection_edit_properties_path(collection)
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

  # update()

  test "update() redirects to login path for logged-out users" do
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {}
    assert_redirected_to login_path
  end

  test "update() updates a collection" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                managing_user_ids: [ users(:admin).id ]
            }
        }
    }
    collection.reload
    assert_equal 1, collection.managing_users.length
    assert_equal users(:admin), collection.managing_users.first
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                manager_id: users(:admin).id
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                primary_unit_id: 99999
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:admin))
    patch "/collections/bogus", {}
    assert_response :not_found
  end

end
