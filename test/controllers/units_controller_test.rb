require 'test_helper'

class UnitsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post units_path, {}
    assert_redirected_to login_path
  end

  test "create() redirects to login page for unauthorized users" do
    log_in_as(users(:norights))
    post units_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200 for authorized users" do
    log_in_as(users(:admin))
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: "New Unit"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a unit" do
    log_in_as(users(:admin))
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: "New Unit"
            }
        }
    }
    assert_not_nil Unit.find_by_title("New Unit")
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for logged-out users" do
    delete "/units/#{units(:unit1).id}"
    assert_redirected_to login_path
  end

  test "destroy() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    delete "/units/#{units(:unit1).id}"
    assert_redirected_to login_path
  end

  test "destroy() destroys the unit" do
    log_in_as(users(:admin))
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:empty)
    delete "/units/#{unit.id}"
    assert_raises ActiveRecord::RecordNotFound do
      Unit.find(unit.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing unit" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    delete "/units/#{unit.id}"
    assert_redirected_to units_path
  end

  test "destroy() returns HTTP 404 for a missing unit" do
    log_in_as(users(:admin))
    delete "/units/bogus"
    assert_response :not_found
  end

  # index()

  test "index() returns HTTP 200" do
    get units_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 200" do
    collections(:described).reindex # this is needed to fully initialize the schema
    get unit_path(units(:unit1))
    assert_response :ok
  end

  # update()

  test "update() redirects to login path for logged-out users" do
    unit = units(:unit1)
    patch "/units/#{unit.id}", {}
    assert_redirected_to login_path
  end

  test "update() redirects to login path for unauthorized users" do
    log_in_as(users(:norights))
    unit = units(:unit1)
    patch "/units/#{unit.id}", {}
    assert_redirected_to login_path
  end

  test "update() updates a unit" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "cats"
            }
        }
    }
    unit.reload
    assert_equal "cats", unit.title
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:admin))
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent units" do
    log_in_as(users(:admin))
    patch "/units/bogus", {}
    assert_response :not_found
  end

end
