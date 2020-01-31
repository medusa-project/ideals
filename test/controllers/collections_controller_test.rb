require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    log_in_as(user_identity(:admin))
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for unauthorized users" do
    log_out
    post collections_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200 for authorized users" do
    post collections_path, {
        xhr: true,
        params: {
            primary_unit_id: units(:unit1).id,
            collection: {
                title: "New Collection"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a collection" do
    post collections_path, {
        xhr: true,
        params: {
            primary_unit_id: units(:unit1).id,
            collection: {
                title: "New Collection"
            }
        }
    }
    assert_not_nil Collection.find_by_title("New Collection")
  end

  test "create() returns HTTP 400 for illegal arguments" do
    post collections_path, {
        xhr: true,
        params: {
            collection: {
                title: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for unauthorized users" do
    log_out
    delete "/collections/#{collections(:collection1).id}"
    assert_redirected_to login_path
  end

  test "destroy() destroys the collection" do
    collection = collections(:collection1)
    delete "/collections/#{collection.id}"
    assert_raises ActiveRecord::RecordNotFound do
      Collection.find(collection.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing collection" do
    collection = collections(:collection1)
    primary_unit = collection.primary_unit
    delete "/collections/#{collection.id}"
    assert_redirected_to primary_unit
  end

  test "destroy() returns HTTP 404 for a missing element" do
    delete "/elements/bogus"
    assert_response :not_found
  end

  # update()

  test "update() redirects to login path for unauthorized users" do
    log_out
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {}
    assert_redirected_to login_path
  end

  test "update() updates a collection" do
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                title: "cats"
            }
        }
    }
    collection.reload
    assert_equal "cats", collection.title
  end

  test "update() returns HTTP 200" do
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                title: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    collection = collections(:collection1)
    patch "/collections/#{collection.id}", {
        xhr: true,
        params: {
            collection: {
                title: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    patch "/collections/bogus", {}
    assert_response :not_found
  end

end
